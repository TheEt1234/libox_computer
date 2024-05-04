libox_computer = {
    basename = "libox_computer:laptop"
}
local MP = minetest.get_modpath(minetest.get_current_modname())
dofile(MP .. "/sandbox.lua")
dofile(MP .. "/frontend.lua")

local nodebox = {
    type = "fixed",
    fixed = {
        { -0.5, -0.5, -0.5, 0.5,   -0.25, 0.5 }, -- base
        { -0.5, -0.5, -0.5, -0.25, 0.5,   0.5 }, -- screen
    }
}

local palette
if minetest.global_exists("unifieddyes") then
    palette = "unifieddyes_palette_colorwallmounted.png"
else
    palette = "^[colorize:252D9E"
end
minetest.register_node(libox_computer.basename, {
    drawtype = "nodebox",
    tiles = {
        "laptop_up.png",
        "^[colorize:black",
        "laptop_screen.png",

        "laptop_back.png",
        "laptop_side2.png",
        "laptop_side1.png",
    },
    palette = palette,
    paramtype = "light",
    light_source = minetest.LIGHT_MAX,
    paramtype2 = "color4dir",
    is_ground_content = false,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        libox_computer.ui(meta)
    end,
    on_receive_fields = libox_computer.on_receive_fields,
    drop = libox_computer.basename,
    groups = {
        cracky = 1,
        ud_param2_colorable = 1, -- for testing, don't actually waste dyes on this lmao
        no_silktouch = 1,
    },
    sunlight_propagates = true,
    node_box = nodebox,
    is_luacontroller = false -- yeah, it's not a luacontroller
})
