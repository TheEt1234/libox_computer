--[[
    Laptop:
    | silicon | silicon | silicon |
    | touchscreen | mooncontroller | digimese |
    | silicon | silicon | silicon |

    Fallbacks:
         mooncontroller -> mesecons luacontroller
    Recipe depends on:
        default, mesecons materials, mooncontroller or mesecons luacontroller

    Robot:
    | digi chest | digi chest | digi chest |
    | pipeworks_accel_tube | laptop | pipeworks digiline injector |
    | pipeworks node breaker | pipeworks deployer | pipeworks dispenser |

    Fallbacks:
        digi chest -> chest
        pipeworks* -> diamond
    Recipe depends on:
        default, (digilines OR default), (pipeworks OR default), libox_computer (duhhh)


    Attempted recipe game compatibility: none
]]


local luacontroller

if minetest.get_modpath("mooncontroller") then
    luacontroller = "mooncontroller:mooncontroller0000"
elseif minetest.get_modpath("mesecons_luacontroller") then
    luacontroller = "mesecons_luacontroller:luacontroller0000"
end
if minetest.get_modpath("mesecons_materials") and luacontroller then
    minetest.register_craft({
        type = "shaped",
        output = libox_computer.basename_laptop,
        recipe = {
            {},
            {},
            {},
        }
    })
end
