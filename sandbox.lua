--[[
    Defines/handles:
        - settings
        - creating
        - executing
        - environment
        - yield behaviour
    Basically a highly specific extension of libox
]]

local api = {}

local settings = libox_computer.settings

function api.raw_print(meta, text)
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

local function get_color_laptop(pos)
    return function(n)
        if type(n) ~= "number" then return false end
        if n < 0 then return false end
        if n > 64 then return false end -- 64 COLORZ!!!

        local n = math.floor(n)

        local node = minetest.get_node(pos)

        node.param2 = math.floor(node.param2 % 4 + n * 4)
        minetest.swap_node(pos, node)
    end
end

local function safe_coroutine_resume(...)
    --[[
    THIS USES RAW PCALL..... AAND CALLS STUFF FROM THE USER
    so we need to be very careful
    and by that i mean we can't use sandbox_lib_f because that will allow the user to (""):rep(math.huge)
    ]]
    local retvalue = {
        coroutine.resume(co, ...)
    }
    if not debug.gethook() then
        error("Code timed out! (from coroutine.resume)", 2)
    end
    return retvalue
end

function api.create_environment(pos)
    local base = libox.create_basic_environment()
    local meta = minetest.get_meta(pos)
    local mem = minetest.deserialize(meta:get_string("mem") or "") or {}
    meta:set_string("term_text", "")

    local add = {
        pos = vector.copy(pos),
        yield = coroutine.yield,
        print = libox.sandbox_lib_f(get_print(meta)),
        clearterm = libox.sandbox_lib_f(get_clearterm(meta)),
        settings = table.copy(settings),
        digiline_send = libox.sandbox_lib_f(get_digiline_send(pos)),
        heat = mesecon.get_heat(pos),
        heat_max = settings.heat_max,
        color_laptop = libox.sandbox_lib_f(get_color_laptop(pos)),

        gui = libox.sandbox_lib_f(
            libox_computer.touchscreen_protocol.get_touchscreen_ui(meta)
        ),

        code = meta:get_string("code"),
        mem = mem,

        coroutine = {
            create = coroutine.create,
            resume = safe_coroutine_resume,
            status = coroutine.status,
            yield = coroutine.yield,
        },
    }
    for k, v in pairs(add) do base[k] = v end
    return base
end

function api.create_sandbox(pos) -- position, not meta, because create_environment depends on pos to get things like heat and.. the position
    local meta = minetest.get_meta(pos)
    meta:set_string("errmsg", "")
    meta:set_int("creation_time", os.time())
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

local function remove_functions(obj)
    local function is_bad(x)
        return type(x) == "function" or type(x) == "userdata" or type(x) == "thread"
    end

    if is_bad(obj) then
        return nil
    end

    -- Make sure to not serialize the same table multiple times, otherwise
    -- writing mem.test = mem in the Luacontroller will lead to infinite recursion
    local seen = {}

    local function rfuncs(x)
        if x == nil then return end
        if seen[x] then return end
        seen[x] = true
        if type(x) ~= "table" then return end

        for key, value in pairs(x) do
            if is_bad(key) or is_bad(value) then
                x[key] = nil
            else
                if type(key) == "table" then
                    rfuncs(key)
                end
                if type(value) == "table" then
                    rfuncs(value)
                end
            end
        end
    end

    rfuncs(obj)

    return obj
end

function api.save_mem(meta, mem)
    local mem = remove_functions(mem) -- safe because we remove the fun stuff

    -- we dont to validate mem for size, as the entire environment gets validated for it
    -- worst case mem is 20 megabytes
    meta:set_string("mem", minetest.serialize(mem))
end

local function yield_logic(pos, meta, value)
    local id = meta:get_string("ID")
    if type(value) == "string" then value = { type = value } end
    if type(value) == "number" then
        value = {
            type = "wait",
            time = value
        }
    end
    if type(value) ~= "table" then return end
    if value.type == nil then return end

    if type(value.type) ~= "string" then return end

    if value.time and type(value.time) ~= "number" then return end
    if value.time and value.time < settings.min_delay then value.time = settings.min_delay end

    if value.type == "stop" then
        api.report_error(meta, "Sandbox stopped.")
        libox.coroutine.active_sandboxes[id] = nil
    elseif value.type == "wait" and value.time then
        meta:set_int("is_waiting", 1) -- ignore all incoming events
        mesecon.queue:add_action(pos, "lb_wait", { id }, value.time, id, 1)
    elseif value.type == "await" and value.time then
        mesecon.queue:add_action(pos, "lb_await", { id }, value.time, id, 1)
    end
end

function api.run_sandbox(pos, event)
    local meta = minetest.get_meta(pos)
    local id = meta:get_string("ID")
    if libox.coroutine.is_sandbox_dead(id) then
        return -- nothing to do
    end
    local is_waiting = (meta:get_int("is_waiting") == 1) or false

    if is_waiting then -- ignore events when waiting
        return
    end

    if mesecon.do_overheat(pos) then
        api.report_error(meta, "Overheated!")
        libox.coroutine.active_sandboxes[id] = nil
        return
    end

    local ok, errmsg_or_value = libox.coroutine.run_sandbox(id, event or { type = "program" })
    local sandbox = libox.coroutine.active_sandboxes[id]
    if sandbox ~= nil and sandbox.env ~= nil then
        api.save_mem(meta,
            libox.coroutine.active_sandboxes[id].env.mem -- spooky
        )
    end
    if not ok then
        api.report_error(meta, tostring(errmsg_or_value))
        libox.coroutine.active_sandboxes[id] = nil
    else
        yield_logic(pos, meta, errmsg_or_value)
    end
end

local delay = settings.sandbox_delay

function api.wake_up_and_run(pos, event)
    local meta = minetest.get_meta(pos)
    local id = meta:get_string("ID")
    local creation_time = meta:get_int("creation_time") or math.huge

    local is_dead = libox.coroutine.is_sandbox_dead(id)
    local creation_time_check_success = creation_time < (os.time() - delay)

    if is_dead and creation_time_check_success then
        api.create_sandbox(pos)
    end
    if (not creation_time_check_success) and is_dead then
        return api.report_error(meta,
            "Sandbox ratelimit reached, retry later (" .. delay .. " second limit).")
    end
    return api.run_sandbox(pos, event)
end

mesecon.queue:add_function("lb_wait", function(pos, id)
    if libox.coroutine.is_sandbox_dead(id) then return end -- server restart maybe? but that doesn't matter because the sandbox is gone.
    minetest.get_meta(pos):set_int("is_waiting", 0)
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
