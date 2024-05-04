--[[
    Defines/handles:
        - settings
        - creating
        - executing
        - environment
        - yield behaviour

]]

local api = {}

local settings = libox_computer.settings

api.raw_print = function(meta, text)
    local old_text = meta:get_string("term_text")
    meta:set_string("term_text", string.sub(old_text .. text, -100000, -1))
    libox_computer.ui(meta)
end

function api.report_error(meta, text, preceeding_text)
    local preceeding_text = preceeding_text or "[ERROR] "
    api.raw_print(meta, preceeding_text .. text .. "\n")
    meta:set_string("errmsg", text)
    libox_computer.ui(meta)
end

local function get_digiline_send(pos)
    return function(channel, msg)
        if type(channel) == "string" then
            if #channel > settings.chan_maxlen then
                return "Channel string too long"
            elseif (type(channel) ~= "string" and type(channel) ~= "number" and type(channel) ~= "boolean") then
                return "Channel must be string, number or boolean."
            end
            local msg, msg_cost = libox.digiline_sanitize(msg, settings.allow_functions_in_digiline_messages,
                libox_computer.wrap)
            if msg == nil or msg_cost > settings.maxlen then
                return "Too complex or contained invalid data"
            end
        end
        mesecon.queue:add_action(pos, "lb_digiline_relay", { channel, msg })
    end
end


local function get_print(meta) -- mooncontroller like
    return function(param, nolf)
        if param == nil then param = "" end
        local delim = "\n"
        if nolf then delim = "" end
        if type(param) == "string" then
            api.raw_print(meta, param .. delim)
        else
            api.raw_print(meta, dump(param) .. delim)
        end
    end
end
local function get_clearterm(meta)
    return function() meta:set_string("term_text", "") end
end


function api.create_environment(pos)
    local base = libox.create_basic_environment()
    local meta = minetest.get_meta(pos)
    meta:set_string("term_text", "")
    local add = {
        pos = vector.copy(pos),
        yield = coroutine.yield, -- maybe allow coroutine creation?
        print = libox.sandbox_lib_f(get_print(meta)),
        clearterm = libox.sandbox_lib_f(get_clearterm(meta)),
        settings = table.copy(settings),
        digiline_send = libox.sandbox_lib_f(get_digiline_send(pos)),
        heat = mesecon.get_heat(pos),
        color_laptop = libox.sandbox_lib_f(function(n)
            if type(n) ~= "number" then return false end
            if n < 1 then return false end
            if n > 16 then return false end
            n = math.floor(n)
            n = n * 2 -- yeah, TODO: MOAR COLORZ!!
            local node = minetest.get_node(pos)
            local param2 = node.param2
            local rot = param2 % 4
            -- so if division by 4 yields the pallete index then...
            local pallete_index = n * 4
            -- and we just... set the node
            node.param2 = math.floor(rot + pallete_index)
            minetest.swap_node(pos, node)
        end),
        gui = libox.sandbox_lib_f(libox_computer.touchscreen_protocol.get_touchscreen_ui(meta))
    }
    for k, v in pairs(add) do base[k] = v end
    return base
end

function api.create_sandbox(pos) -- position, not meta, because create_environment depends on pos to get things like heat and.. the position
    local meta = minetest.get_meta(pos)
    meta:set_string("errmsg", "")
    local code = meta:get_string("code")
    local ID = libox.coroutine.create_sandbox({
        code = code,
        is_garbage_collected = true,
        env = api.create_environment(pos),
        time_limit = settings.time_limit,
        hook_time = 10,
        size_limit = settings.size_limit,
    })

    meta:set_string("ID", ID)
    meta:set_int("is_waiting", 0)
end

function api.run_sandbox(pos, event)
    local meta = minetest.get_meta(pos)
    local id = meta:get_string("ID")
    if libox.coroutine.is_sandbox_dead(id) then
        return -- nothing to do
    end
    local is_waiting = (meta:get_int("is_waiting") == 1) or false

    if is_waiting then -- ignore events when waiting
        if type(event) == "table" and event.type and event.type == "wait" then
            meta:set_int("is_waiting", 0)
        else
            return
        end
    end

    if mesecon.do_overheat(pos) then
        api.report_error(meta, "Overheated!")
        libox.coroutine.active_sandboxes[id] = nil
    end



    local ok, errmsg_or_value = libox.coroutine.run_sandbox(id, event or { type = "program" })
    if not ok then
        api.report_error(meta, tostring(errmsg_or_value))
        libox.coroutine.active_sandboxes[id] = nil
    elseif errmsg_or_value == "stop" or errmsg_or_value == { type = "stop" } then
        api.report_error(meta, "Sandbox stopped.")
        libox.coroutine.active_sandboxes[id] = nil
    else
        -- THE YIELD PROCESSOR
        -- we use mesecons ActionQueue™ for this
        -- TODO: refactor the code maybe? i mean its messy as crap

        local value = errmsg_or_value
        if type(value) == "number" then
            value = {
                type = "wait",
                time = value,
            }
        end
        if type(value) == "string" then
            if value == "await" then
                value = {
                    type = "await",
                }
            end
        end
        if type(value) ~= "table" then return end -- await without time argument is that
        if value.type == nil then return end

        if value.type == "wait" and type(value.time) == "number" then
            local time = value.time
            meta:set_int("is_waiting", 1) -- ignore all incoming events

            if time < settings.min_delay then time = settings.min_delay end
            mesecon.queue:add_action(pos, "lb_wait", { id }, time, id, 1)
        elseif value.type == "await" then
            if not value.time or type(value.time) ~= "number" then return end -- await without time argument is that

            if value.time < settings.min_delay then value.time = settings.min_delay end
            mesecon.queue:add_action(pos, "lb_await", { id }, value.time, id, 1)
        end
    end
end

local delay = 20 -- if 20 seconds pass you can create another sandbox
function api.wake_up_and_run(pos, event)
    local meta = minetest.get_meta(pos)
    local id = meta:get_string("ID")
    local creation_time = meta:get_int("creation_time") or -delay

    local is_dead = libox.coroutine.is_sandbox_dead(id)
    local creation_time_check_success = creation_time < (os.clock() - 20)
    if is_dead and creation_time_check_success then
        meta:set_int("creation_time", os.clock())
        api.create_sandbox(pos)
    end
    if (not creation_time_check_success) and (not is_dead) then
        return api.report_error(meta,
            "Sandbox ratelimit reached, retry later (" .. delay .. " second limit).")
    end
    return api.run_sandbox(pos, event)
end

mesecon.queue:add_function("lb_wait", function(pos, id)
    if libox.coroutine.is_sandbox_dead(id) then return end -- server restart maybe? but that doesn't matter because the sandbox is gone.
    api.run_sandbox(pos, {
        type = "wait"
    })
end)

mesecon.queue:add_function("lb_await", function(pos, id)
    if libox.coroutine.is_sandbox_dead(id) then return end -- server restart maybe? but that doesn't matter because the sandbox is gone.
    api.run_sandbox(pos, {
        type = "await"
    })
end)

mesecon.queue:add_function("lb_digiline_relay", function(pos, channel, msg)
    local id = minetest.get_meta(pos):get_string("ID")
    if libox.coroutine.is_sandbox_dead(id) then return end -- server restart maybe? but that doesn't matter because the sandbox is gone.
    digilines.receptor_send(pos, digiline.rules.default, channel, msg)
end)

libox_computer.sandbox = api
