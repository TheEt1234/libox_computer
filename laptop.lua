--[[
    Registration, yeah short i know
]]

local nodebox = {
    type = "fixed",
    fixed = {
        { -0.5, -0.5, -0.5, 0.5,   -0.25, 0.5 }, -- base
        { -0.5, -0.5, -0.5, -0.25, 0.5,   0.5 }, -- screen
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
    digiline = {
        receptor = {},
        effector = {
            action = function(pos, _, channel, msg)
                local msg, _cost = libox.digiline_sanitize(msg,
                    libox_computer.settings.allow_functions_in_digiline_messages, libox_computer.wrap)
                libox_computer.sandbox.wake_up_and_run(pos, {
                    type = "digiline",
                    channel = channel,
                    msg = msg
                })
                -- digilines wake the sandbox up now... yes... and yes its not as unbalanced as one may believe
            end
        }
    },
    on_dig = function(pos, node, digger)
        local meta = minetest.get_meta(pos)
        libox.coroutine.active_sandboxes[meta:get_string("ID") or ""] = nil
        minetest.node_dig(pos, node, digger)
        return true
    end,
    on_blast = function(pos, _intensity)
        local meta = minetest.get_meta(pos)
        libox.coroutine.active_sandboxes[meta:get_string("ID") or ""] = nil
        minetest.remove_node(pos)
    end,
    mod_origin = "libox_computer",
})
