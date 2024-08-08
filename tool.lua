--[[
    Laptop programer
    [grey]All it currently does is reset the laptop to the editor ui
]]


local function random_sign()
    local r = math.random(0, 1)
    if r == 0 then return -1 else return 1 end
end

local function random_with_random_sign()
    return math.random() * random_sign()
end

local function do_it(user, pointed_thing)
    if pointed_thing.type ~= "node" then return end

    user = user:get_player_name()
    local under = pointed_thing.under
    if minetest.is_protected(under, user) then
        minetest.record_protection_violation(under, user)
        return
    end

    local node = minetest.get_node(under)
    if not (minetest.registered_nodes[node.name].mod_origin == "libox_computer") then
        return
    end

    local meta = minetest.get_meta(under)
    local ID = meta:get_string("ID")

    meta:set_int("ts_ui", 0)
    libox.coroutine.active_sandboxes[ID] = nil
    meta:set_string("ID", "")
    libox_computer.ui(meta)

    for _ = 1, 25 do
        minetest.add_particle({
            pos = vector.copy(under):apply(function(x)
                return x + random_with_random_sign() * 2
            end),
            expirationtime = math.random(),
            velocity = { x = 0, y = 1 + math.random(), z = 0 },
            acceleration = vector.zero():apply(random_with_random_sign),
            drag = vector.zero():apply(random_with_random_sign),
            texture = "^[colorize:green",
            playername = user,
            glow = 14,
        })
    end
end

minetest.register_craftitem("libox_computer:tool", {
    description = "Libox computer tool\n" ..
        minetest.colorize("#777777",
            "All it currently does is turn off a libox robot/laptop"),
    short_description = "Libox computer tool",
    inventory_image = "laptop_tool.png",
    stack_max = 1,
    range = 10,
    light_source = 14,
    on_use = function(_, user, pointed_thing)
        return do_it(user, pointed_thing)
    end,
})
