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

local function is_vector_within_range(vec)
    return vector.in_area(vec, {
        x = -settings.range,
        y = -settings.range,
        z = -settings.range
    }, {
        x = settings.range,
        y = settings.range,
        z = settings.range
    })
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
        move = function(rpos)
            --[[
                Problem: Yield logic can't handle our shenanigans (fair)
                so we need to somehow inform the system that the position of the node has been changed
                ummmmm
                OH RIGHT I HAVE AN IDEA
                yield({
                    type = "move",
                    rpos = {vector}
                })

                and this simply being an alias
            ]]
            return coroutine.yield({
                type = "move",
                rpos = rpos,
            })
        end
    }


    if minetest.global_exists("pipeworks") then
        add.inject_item = libf(function(item, rpos)
            --[[
                PROBLEM:
                we need PROOF of the item's existance

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

        add.node = {
            --[[
                Assumbtion: all the positions in here are relative
            ]]
            is_protected = libf(function(rpos, who)
                if who == nil then who = owner end
                if not is_vector_within_range(rpos) then
                    return "Vector not within range."
                end
                return minetest.is_protected(pos + rpos, who)
            end),
            get = libf(function(rpos)
                if not is_vector_within_range(rpos) then
                    return "Vector not within range."
                end

                return table.copy(minetest.get_node(pos + rpos))
            end),
            place = libf(libox_computer.get_place(pos, meta, inv, owner)),
            dig = libf(libox_computer.get_break(pos, meta, inv, owner)),
        }
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

local yield_logic_funcs = {}

yield_logic_funcs.stop = {
    types = {},
    f = function(pos, meta, id)
        libox_computer.report_error(meta, "Sandbox stopped.")
        libox.coroutine.active_sandboxes[id] = nil
    end
}
yield_logic_funcs.wait = {
    types = {
        time = "number"
    },
    f = function(pos, meta, id, args)
        local time = args.time
        time = math.max(settings.min_delay, time)
        meta:set_int("is_waiting", 1) -- ignore all incoming events
        mesecon.queue:add_action(pos, "lb_wait", { id }, time, id, 1)
    end
}
yield_logic_funcs.await = {
    types = {
        time = "number"
    },
    f = function(pos, meta, id, args)
        local time = args.time
        time = math.max(settings.min_delay, time)
        mesecon.queue:add_action(pos, "lb_await", { id }, time, id, 1)
    end
}

yield_logic_funcs.move = {
    types = {
        rpos = is_valid_rpos,
    },
    f = function(pos, meta, id, args)
        local HARDCODED_MOVE_TIME = 0.1

        local rpos = args.rpos

        local use_pos = pos + vector.new(rpos.x, rpos.y, rpos.z)
        local node = minetest.get_node(use_pos)

        if minetest.registered_nodes[node.name].buildable_to == false then
            return "There is already a solid node there"
        end
        if node.name == "ignore" then
            return "Area wasn't loaded"
        end
        -- ok cool we can override the node now i guess
        -- wait no protection
        local owner = meta:get_string("owner")
        if minetest.is_protected(use_pos, owner) then
            return "Protected."
        end

        -- now how do we "swap" the node use_pos with pos
        -- idk lmao

        -- how about we use the aproach that the mesecons mvps did
        local metatable = meta:to_table()
        local og_node = minetest.get_node(pos)
        minetest.remove_node(pos)
        minetest.set_node(use_pos, og_node)
        pos = use_pos
        meta = minetest.get_meta(pos)
        meta:from_table(metatable)
        libox_computer.ui(meta)

        meta:set_int("is_waiting", 1) -- ignore all incoming events
        mesecon.queue:add_action(pos, "lb_wait", { id }, HARDCODED_MOVE_TIME, id, 1)
    end
}

local function yield_logic(pos, meta, args)
    local id = meta:get_string("ID")
    if type(args) == "number" then
        args = {
            type = "wait",
            time = args
        }
    end
    if type(args) == "string" then
        args = {
            type = args
        }
    end
    if type(args) ~= "table" then return end
    local yield_f = yield_logic_funcs[args.type]
    if yield_f == nil then
        return -- await
    end
    for k, v in pairs(yield_f.types) do
        if type(v) == 'function' then
            if v(args[k]) == false then
                mesecon.queue:add_action(pos, "lb_err", { id, "Invalid type:" .. k }, settings.min_delay, id, 1)
                return
            end
        elseif type(v) == "string" then
            if type(args[k]) ~= v then
                mesecon.queue:add_action(pos, "lb_err", { id, "Invalid type: " .. k }, settings.min_delay, id, 1)
                return
            end
        end
    end

    local ret_value = yield_f.f(pos, meta, id, args)
    if type(ret_value) == "string" then
        mesecon.queue:add_action(pos, "lb_err", { id, ret_value }, settings.min_delay, id, 1)
        return
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
    libox_computer.ui(meta)
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

mesecon.queue:add_function("lb_err", function(pos, id, errmsg)
    if libox.coroutine.is_sandbox_dead(id) then return end -- server restart maybe? but that doesn't matter because the sandbox is gone.
    minetest.get_meta(pos):set_int("is_waiting", 0)
    api.run_sandbox(pos, {
        type = "error",
        errmsg = errmsg,
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
