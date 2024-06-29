--[[
    Registration, yeah short i know

    also setting the is_luacontroller to false is a good idea because
    mods might assume that, if it is a luacontroller, it shares the luacontroller api (it really doesn't)
]]

local nodebox = {
    type = "fixed",
    fixed = {
        { -0.5, -0.5, -0.5, 0.5,   -0.25, 0.5 }, -- base
        { -0.5, -0.5, -0.5, -0.25, 0.5,   0.5 }, -- screen
    }
}

local function allow_metadata_stuff(pos, player, count)
    if minetest.get_meta(pos):get_int("locked_inv") == 0 then return count end
    if minetest.is_protected(pos, player:get_player_name()) then
        return 0
    end
    return count
end

local on_dig = function(pos, node, digger)
    local meta = minetest.get_meta(pos)
    libox.coroutine.active_sandboxes[meta:get_string("ID") or ""] = nil
    minetest.node_dig(pos, node, digger)
    return true
end

local on_blast = function(pos, _)
    local meta = minetest.get_meta(pos)
    libox.coroutine.active_sandboxes[meta:get_string("ID") or ""] = nil
    minetest.remove_node(pos)
end


local digiline = {
    receptor = {},
    effector = {
        action = function(pos, _, channel, msg)
            msg = libox.digiline_sanitize(msg, libox_computer.settings.allow_functions_in_digiline_messages,
                libox_computer.digiline_wrap)
            libox_computer.sandbox.wake_up_and_run(pos, {
                type = "digiline",
                channel = channel,
                msg = msg
            })
        end
    }
}


minetest.register_node(libox_computer.basename_laptop, {
    description = "Libox laptop",
    drawtype = "nodebox",
    tiles = {
        "laptop_up.png",
        "^[colorize:black",
        "laptop_screen.png",

        "laptop_back.png",
        "laptop_side.png^[transformR90",
        "laptop_side.png",
    },
    palette = "laptop_palette.png",
    paramtype = "light",
    light_source = minetest.LIGHT_MAX,
    paramtype2 = "color4dir",
    is_ground_content = false,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_int("ts_ui", 0)
        libox_computer.ui(meta)
    end,
    on_receive_fields = libox_computer.on_receive_fields,
    drop = libox_computer.basename_laptop,
    groups = {
        cracky = 1,
    },
    sunlight_propagates = true,
    node_box = nodebox,
    is_luacontroller = false, -- yeah, it's not a luacontroller
    digiline = digiline,
    on_dig = on_dig,
    on_blast = on_blast,
    mod_origin = "libox_computer",
})

--[[
    Registration, yeah short i know
    And yeah i know the robot looks a bit weird but like... i dont want it to look like a person... i want it to look like an omnipotent cube
]]


local pipeworks_transform = ""
if minetest.get_modpath("pipeworks") then
    pipeworks_transform = "^pipeworks_tube_connection_metallic.png"
end

local function bool2num(x)
    if x then return 1 else return 0 end
end

minetest.register_node(libox_computer.basename_robot, {
    description = "Libox robot",
    tiles = {
        "laptop_up.png",
        "^[colorize:black",
        "laptop_screen.png",

        "laptop_back.png",
        "laptop_side.png^[transformR90" .. pipeworks_transform,
        "laptop_side.png" .. pipeworks_transform,
    },
    palette = "robot_palette.png",
    paramtype = "light",
    light_source = minetest.LIGHT_MAX,
    paramtype2 = "colorfacedir", -- only 8 colors
    is_ground_content = false,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        meta:set_int("robot", 1)
        meta:set_int("ts_ui", 0)
        inv:set_size("main", 128) -- way more than double than a chest, if you need more, use other storage options idk
        libox_computer.ui(meta)
    end,
    after_place_node = function(pos, placer, _, _)
        minetest.get_meta(pos):set_string("owner", placer:get_player_name())
    end,
    on_receive_fields = libox_computer.on_receive_fields,
    drop = libox_computer.basename_robot,
    groups = {
        cracky = 1,
        tubedevice = 1,
        tubedevice_receiver = 1,
        not_in_creative_inventory = bool2num(not libox_computer.settings.allow_robots),
    },
    sunlight_propagates = true,
    is_luacontroller = false, -- yeah, it's not a luacontroller
    digiline = digiline,
    on_dig = on_dig,
    on_blast = on_blast,
    tube = {
        insert_object = function(pos, _, stack, _)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            return inv:add_item("main", stack)
        end,
        can_insert = function(pos, _, stack, _)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            return inv:room_for_item("main", stack)
        end,
        input_inventory = "main",
        connect_sides = {
            left = 1, right = 1, front = 1, back = 1, top = 1, bottom = 1
        }
    },
    mod_origin = "libox_computer",


    allow_metadata_inventory_move = function(pos, _, _, _, _, count, player)
        return allow_metadata_stuff(pos, player, count)
    end,
    allow_metadata_inventory_put = function(pos, _, _, stack, player)
        return allow_metadata_stuff(pos, player, stack:get_count())
    end,
    allow_metadata_inventory_take = function(pos, _, _, stack, player)
        return allow_metadata_stuff(pos, player, stack:get_count())
    end
})
