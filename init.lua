local settings = minetest.settings
libox_computer = {
    basename_laptop = "libox_computer:laptop",
    basename_robot = "libox_computer:robot",
    is_from_mod = {
        ["libox_computer:laptop"] = true,
        ["libox_computer:robot"] = true,
    },
    settings = {
        time_limit = tonumber(settings:get("libox_computer_time_limit")) or 3000, -- 3 miliseconds
        min_delay = 1 / (mesecon.setting("overheat_max", 20) - 2),
        size_limit = (1024 * 1024 * 10),                                          -- 10 *megabytes*
        chan_maxlen = 256,
        maxlen = 1024 * 5,                                                        -- 50 kilobytes
        heat_max = mesecon.setting("overheat_max", 20),
        cooldown_time = mesecon.setting("cooldown_time", 2.0),
        cooldown_step = mesecon.setting("cooldown_granularity", 0.5),
        allow_functions_in_digiline_messages = settings:get("libox_computer_allow_functions") or false,
        sandbox_delay = settings:get_bool("libox_computer_sandbox_delay") or 5,
    }
}

if tonumber(settings:get("libox_computer_size_limit")) then
    libox_computer.settings.size_limit = 1024 * 1024 * tonumber(settings:get("libox_computer_size_limit"))
end



local MP = minetest.get_modpath(minetest.get_current_modname())
dofile(MP .. "/touchscreen_protocol.lua")
dofile(MP .. "/utils.lua")
dofile(MP .. "/sandbox.lua")
dofile(MP .. "/frontend.lua")

dofile(MP .. "/laptop.lua")
dofile(MP .. "/robot.lua")

dofile(MP .. "/tool.lua")
