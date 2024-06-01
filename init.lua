local settings = minetest.settings

local function get_bool_setting_or_default(settingname, default)
    local s = minetest.settings:get_bool(settingname)
    if s == nil then
        return default
    else
        return s
    end
end

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
        allow_functions_in_digiline_messages = get_bool_setting_or_default("libox_computer_allow_functions", false),
        sandbox_delay = settings:get_bool("libox_computer_sandbox_delay") or 5,
        range = tonumber(settings:get("libox_computer_range")) or 3,
        set_node_delay = tonumber(settings:get("libox_computer_set_node_delay")) or 0.1,
        allow_robots = get_bool_setting_or_default("libox_computer_allow_robots", true)
    }
}

if tonumber(settings:get("libox_computer_size_limit")) then
    libox_computer.settings.size_limit = 1024 * 1024 * tonumber(settings:get("libox_computer_size_limit"))
end

if not minetest.global_exists("jit") then
    minetest.log("warn",
        "[libox_computer] Minetest not compiled with luajit, libox_computer with PUC lua is not officially supported")
end


local MP = minetest.get_modpath(minetest.get_current_modname())
dofile(MP .. "/touchscreen_protocol.lua")
dofile(MP .. "/robot_actions.lua")

dofile(MP .. "/utils.lua")
dofile(MP .. "/sandbox.lua")
dofile(MP .. "/frontend.lua")

dofile(MP .. "/registrations.lua")
dofile(MP .. "/tool.lua")

dofile(MP .. "/support.lua")
