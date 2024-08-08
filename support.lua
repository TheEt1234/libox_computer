-- Oh the fun, like i had with https://github.com/TheEt1234/libox_controller/blob/master/support.lua

-- wrench support, licensed under LGPLv2.1, by mt-mods, the license can be found at https://github.com/mt-mods/wrench/blob/master/LICENSE
-- also modified

if minetest.global_exists("wrench") then
    local S = wrench.translator

    local def_laptop = {
        drop = true,
        metas = {
            data = wrench.META_TYPE_STRING,
            creation_time = wrench.META_TYPE_INT,
            mem = wrench.META_TYPE_STRING,
            ts_ui = wrench.META_TYPE_INT,
            is_waiting = wrench.META_TYPE_INT,
            formspec = wrench.META_TYPE_STRING,
            ID = wrench.META_TYPE_STRING,

            term_text = wrench.META_TYPE_STRING,
            tab = wrench.META_TYPE_INT,
            code = wrench.META_TYPE_STRING,

        },
        description = function()
            return S("Laptop with code")
        end,
        before_pickup = function(_, meta, _, _)
            local ID = meta:get_string("ID")
            libox.coroutine.active_sandboxes[ID] = nil
            meta:set_string("ID", "")
        end
    }

    wrench.register_node(libox_computer.basename_laptop, def_laptop)

    local def_robot = table.copy(def_laptop)
    def_robot.metas = {
        data = wrench.META_TYPE_STRING,
        creation_time = wrench.META_TYPE_INT,
        mem = wrench.META_TYPE_STRING,
        ts_ui = wrench.META_TYPE_INT,
        is_waiting = wrench.META_TYPE_INT,
        formspec = wrench.META_TYPE_STRING,
        ID = wrench.META_TYPE_STRING,

        term_text = wrench.META_TYPE_STRING,
        tab = wrench.META_TYPE_INT,
        code = wrench.META_TYPE_STRING,

        robot = wrench.META_TYPE_INT, -- just a constant 1 lol
        owner = wrench.META_TYPE_STRING,
    }

    def_robot.lists = {
        "main"
    }

    def_robot.description = function()
        return S("Robot with stuff")
    end

    wrench.register_node(libox_computer.basename_robot, def_robot)
end

-- we don't need to include any mesecons debug support as nothing uses node timers
-- because node timers just have some limits that mesecon queue doesn't and also i am too lazy

-- luatool support
if minetest.global_exists("metatool") and minetest.get_modpath("luatool") then
    --[[
        From https://github.com/S-S-X/metatool/blob/master/luatool/nodes/luacontroller.lua#L1
        (also very modified)

        This applies to the following code in the if statement:

            MIT License

            Copyright (c) 2020 SX

            Permission is hereby granted, free of charge, to any person obtaining a copy
            of this software and associated documentation files (the "Software"), to deal
            in the Software without restriction, including without limitation the rights
            to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
            copies of the Software, and to permit persons to whom the Software is
            furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all
            copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
            IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
            FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
            AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
            LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
            OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
            SOFTWARE.
    ]]

    local nodes = {
        libox_computer.basename_laptop,
        libox_computer.basename_robot,
    }

    local luatool = metatool.tool("luatool")


    local ns = metatool.ns('luatool')

    local definition = {
        name = 'libox computer',
        nodes = nodes,
        group = 'libox computer',
    }

    function definition.info(_, _, pos, player, itemstack)
        local meta = minetest.get_meta(pos)
        local mem = meta:get_string("mem")
        return ns.info(pos, player, itemstack, mem, "lua controller")
    end

    function definition.copy(_, _, pos, _)
        local meta = minetest.get_meta(pos)

        -- get and store lua code
        local code = meta:get_string("code")

        -- return data required for replicating this controller settings
        return {
            description = string.format("Lua controller at %s", minetest.pos_to_string(pos)),
            code = code,
        }
    end

    function definition.paste(_, node, pos, player, data)
        -- restore settings and update lua controller, no api available
        local meta = minetest.get_meta(pos)
        if data.mem_stored then
            meta:set_string("mem", data.mem)
        end
        local fields = {
            program = 1,
            code = data.code or meta:get_string("code"),
        }
        local nodedef = minetest.registered_nodes[node.name]
        nodedef.on_receive_fields(pos, "", fields, player)
    end

    luatool:load_node_definition(definition)
end
