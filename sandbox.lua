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

local function get_color_laptop(pos)
    return function(n)
        if type(n) ~= "number" then return false end
        if n < 0 then return false end
        if n > 64 then return false end -- 64 COLORZ!!!

        local n = math.floor(n)

        local node = minetest.get_node(pos)

        node.param2 = math.floor(node.param2 % 4 + n * 4) -- ah math, see minetest api documentation, but basically trust me bro
        minetest.swap_node(pos, node)
    end
end

local function get_color_robot(pos)
    return function(n)
        if type(n) ~= "number" then return false end
        if n < 0 then return false end
        if n > 8 then return false end -- only 8 colors

        local n = math.floor(n)

        local node = minetest.get_node(pos)

        node.param2 = math.floor(node.param2 % 32 + n * 32) -- ah math, see minetest api documentation, but basically trust me bro
        minetest.swap_node(pos, node)
    end
end

local libf = libox.sandbox_lib_f
-- magic that makes a library function safe :tm: -- ok but more specifically it escapes the string sandbox and like does a bunch of stuff

function api.create_laptop_environment(pos)
    local base = libox.create_basic_environment()
    local meta = minetest.get_meta(pos)
    local mem = minetest.deserialize(meta:get_string("mem") or "") or {}
    meta:set_string("term_text", "")

    local add = {
        pos = vector.copy(pos),
        yield = coroutine.yield,
        print = libf(libox_computer.get_print(meta)),
        clearterm = libf(libox_computer.get_clearterm(meta)),
        settings = table.copy(settings),
        digiline_send = libf(libox_computer.get_digiline_send(pos)),
        heat = mesecon.get_heat(pos),
        heat_max = settings.heat_max,
        color_laptop = libf(get_color_laptop(pos)),

        gui = libf(
            libox_computer.touchscreen_protocol.get_touchscreen_ui(meta)
        ),

        code = meta:get_string("code"),
        mem = mem,

        coroutine = {
            create = coroutine.create,
            resume = libox_computer.safe_coroutine_resume,
            status = coroutine.status,
            yield = coroutine.yield,
        },
    }
    for k, v in pairs(add) do base[k] = v end
    return base
end

local function curry(f, ...)
    -- only used to hide data conveniently in this case
    -- but basically see https://wiki.haskell.org/Currying
    -- this is a simpler version of it
    -- i think i might start using this more idk it seems so cool
    local og_arg_arr = { ... }

    return function(...)
        local will_be_supplied = table.copy(og_arg_arr)
        local supplied = { ... }
        for k, v in ipairs(supplied) do
            will_be_supplied[#will_be_supplied + 1] = v
        end
        return f(unpack(will_be_supplied))
    end
end


local function get_safe_ItemStack(f)
    return function(...)
        local x = f(...)

        if type(x) ~= "userdata" and type(x) ~= "table"
            and type(x) ~= "string"
            and x ~= nil then
            return "sorry couldnt get the stack"
        end

        local core = ItemStack(x)
        return core:to_table()
    end
end


local function convert_to_safe_itemstacks(f)
    return function(...)
        local x = f(...)
        local result = {}
        for k, v in pairs(x) do
            if type(v) == "table" then
                result[k] = convert_to_safe_itemstacks(v)
            elseif type(v) == "userdata" and v.to_table then
                result[k] = v:to_table()
            else
                result[k] = v
            end
        end
        return result
    end
end

function api.create_robot_environment(pos)
    local base = libox.create_basic_environment()
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local owner = meta:get_string("owner") or ""
    local mem = minetest.deserialize(meta:get_string("mem") or "") or {}
    meta:set_string("term_text", "")

    local add = {
        traceback = debug.traceback, -- libox.traceback is unsafe to expose, and like... lets give the chance SOME WAY to debug generic errors
        pos = vector.copy(pos),
        yield = coroutine.yield,
        print = libf(libox_computer.get_print(meta)),
        clearterm = libf(libox_computer.get_clearterm(meta)),
        settings = table.copy(settings),
        digiline_send = libf(libox_computer.get_digiline_send(pos)),
        heat = mesecon.get_heat(pos),
        heat_max = settings.heat_max,
        color_robot = libf(get_color_robot(pos)),

        gui = libf(
            libox_computer.touchscreen_protocol.get_touchscreen_ui(meta)
        ),

        code = meta:get_string("code"),
        mem = mem,

        coroutine = {
            create = coroutine.create,
            resume = libox_computer.safe_coroutine_resume,
            status = coroutine.status,
            yield = coroutine.yield,
        },
        -- inventory/pipeworks related
        -- we CANNOT let the user access the ItemStack and MetaRef userdata because its like almost impossible to weigh unless using special logic
        inv = {
            is_empty = libf(curry(inv.is_empty, inv, "main")),
            get_size = libf(curry(inv.get_size, inv, "main")),
            get_stack =
                libf(get_safe_ItemStack(
                    curry(inv.get_stack, inv, "main")
                )),
            get_list = libf(convert_to_safe_itemstacks(curry(inv.get_list, inv, "main"))),

            room_for_item = libf(curry(inv.room_for_item, inv, "main")),
            contains_item = libf(curry(inv.contains_item, inv, "main")),
            lock = libf(function()
                meta:set_int("locked_inv", 1)
            end),
            unlock = libf(function()
                meta:set_int("locked_inv", 0)
            end)
        },

    }


    if minetest.global_exists("pipeworks") then
        add.inject_item = libf(function(item, rpos)
            local function is_valid_rpos(rpos)
                if type(rpos) ~= "table" then return false end
                local valid_rpos_arr = {
                    { x = 1,  y = 0,  z = 0 },
                    { x = -1, y = 0,  z = 0 },
                    { x = 0,  y = 1,  z = 0 },
                    { x = 0,  y = -1, z = 0 },
                    { x = 0,  y = 0,  z = 1 },
                    { x = 0,  y = 0,  z = -1 }
                }
                for k, v in ipairs(valid_rpos_arr) do
                    if rpos.x == v.x and rpos.y == v.y and rpos.z == v.z then return true end
                end
                return false
            end
            --[[
                PROBLEM:
                we need PROOF of the item's existance
                so... its easy if type(item) == "number"
                then we can return what is on that list, if its no good then yeah its just empty

                Also rpos is the relative pos
                sort of like a lazy version of the luatube port
            ]]
            if rpos == nil then rpos = { x = 0, y = 1, z = 0 } end
            if not is_valid_rpos(rpos) then return "rpos isn't valid, do something like { x = 0, y = 1, z = 0 }" end
            rpos = vector.new(rpos.x, rpos.y, rpos.z)

            local stack
            if type(item) == "number" then
                -- we see the index
                stack = inv:get_stack("main", item)

                if stack == nil then
                    return "(Treating item param as index) Pointed to nothing."
                end

                if stack:is_empty() then
                    return "(Treating item param as index) Pointed to empty stack."
                end

                -- delete the item
                inv:set_stack("main", item, ItemStack(""))
            elseif type(item) == "table" or type(item) == "string" then
                -- in this case, we need to search for the itemstack in the list to prove its existance

                stack = ItemStack(item)

                if stack:get_count() > stack:get_stack_max() then -- cant have fun happen
                    stack:set_count(stack:get_stack_max())
                end

                local list = inv:get_list("main")

                local found_stack = nil
                for k, v in ipairs(list) do
                    if v:get_name() == stack:get_name() then
                        found_stack = v
                        inv:set_stack("main", k, ItemStack(""))
                        break
                    end
                end

                if not found_stack then
                    return "Didn't find that item stack"
                else
                    stack = found_stack
                end
            else
                return "Itemstring of invalid type, its a table, string or a number if index"
            end

            pipeworks.tube_inject_item(pos + rpos, pos, rpos, stack, owner, {})
        end)
    end
    for k, v in pairs(add) do base[k] = v end
    return base
end

function api.create_sandbox(pos) -- position, not meta, because create_environment depends on pos to get things like heat and.. the position
    local meta = minetest.get_meta(pos)
    meta:set_string("errmsg", "")
    meta:set_int("creation_time", os.time())
    local is_laptop = meta:get_int("robot") == 0
    local code = meta:get_string("code")

    local env
    if is_laptop then
        env = api.create_laptop_environment(pos)
    else
        env = api.create_robot_environment(pos)
    end

    local ID = libox.coroutine.create_sandbox({
        code = code,
        is_garbage_collected = true,
        env = env,
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
    meta:mark_as_private("mem")
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
        libox_computer.report_error(meta, "Sandbox stopped.")
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
        libox_computer.report_error(meta, "Overheated!")
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
        libox_computer.report_error(meta, tostring(errmsg_or_value))
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
        return libox_computer.report_error(meta,
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
