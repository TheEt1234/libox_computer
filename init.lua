local settings = minetest.settings
libox_computer = {
    basename = "libox_computer:laptop",
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

function libox_computer.wrap(f)
    setfenv(f, {}) -- make the function have to import its environment
    return f
end

local MP = minetest.get_modpath(minetest.get_current_modname())
dofile(MP .. "/touchscreen_protocol.lua")
dofile(MP .. "/sandbox.lua")
dofile(MP .. "/frontend.lua")

local nodebox = {
    type = "fixed",
    fixed = {
        { -0.5, -0.5, -0.5, 0.5,   -0.25, 0.5 }, -- base
        { -0.5, -0.5, -0.5, -0.25, 0.5,   0.5 }, -- screen
    }
}

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
    drop = libox_computer.basename,
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
                -- digilines wake the sandbox up now... yes
            end
        }
    },
    on_dig = function(pos, node, digger)
        local meta = minetest.get_meta(pos)
        libox.coroutine.active_sandboxes[meta:get_string("ID") or ""] = nil
        minetest.node_dig(pos, node, digger)
        return true
    end,
    on_blast = function(pos, intensity)
        local meta = minetest.get_meta(pos)
        libox.coroutine.active_sandboxes[meta:get_string("ID") or ""] = nil
        minetest.remove_node(pos)
    end,
    mod_origin = "libox_computer",
})

dofile(MP .. "/tool.lua")
