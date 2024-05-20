--[[
    Laptop programer
    [grey]All it currently does is reset the laptop to the editor ui
]]


local function random_sign()
    local r = math.random(0, 1)
    if r == 0 then
        return -1
    else
        return 1
    end
end

local function random_with_random_sign()
    return math.random() * random_sign()
end


local function default_on_use(user, pointed_thing)
    user = user:get_player_name()
    if pointed_thing.type ~= "node" then return end
    local under = pointed_thing.under
    if minetest.is_protected(under, user) then
        minetest.record_protection_violation(under, user)
        return
    end
    local node = minetest.get_node(under)
    if not libox_computer.is_from_mod[node.name] then return end

    local meta = minetest.get_meta(under)
    meta:set_int("ts_ui", 0)
    libox_computer.ui(meta)

    -- LISTEN, IT'S A REQUIREMENT!
    -- if you set this to 100 its like really fun
    -- im gonna keep it as that
    -- also its not using particle spawners because... i dont really know how i would use them here like that...

    for _ = 1, 25 do
        minetest.add_particle({
            pos = (
                vector.copy(under):apply(
                    function(x)
                        return x + ((math.random() * 2) * random_sign())
                    end)
            ),
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


local function default_on_place(user, pointed_thing)
    user = user:get_player_name()
    if pointed_thing.type ~= "node" then return end
    local under = pointed_thing.under
    if minetest.is_protected(under, user) then
        minetest.record_protection_violation(under, user)
        return
    end
    local node = minetest.get_node(under)
    if not libox_computer.is_from_mod[node.name] then return end

    local meta = minetest.get_meta(under)
    meta:set_int("ts_ui", 0)
    local ID = meta:get_string("ID")
    libox.coroutine.active_sandboxes[ID] = nil
    meta:set_string("ID", "")
    libox_computer.ui(meta)

    -- LISTEN, IT'S A REQUIREMENT!
    -- if you set this to 100 its like really fun
    -- im gonna keep it as that
    -- also its not using particle spawners because... i dont really know how i would use them here like that...

    for _ = 1, 25 do
        minetest.add_particle({
            pos = (
                vector.copy(under):apply(
                    function(x)
                        return x + ((math.random() * 2) * random_sign())
                    end)
            ),
            expirationtime = math.random(),
            velocity = { x = 0, y = 1 + math.random(), z = 0 },
            acceleration = vector.zero():apply(random_with_random_sign),
            drag = vector.zero():apply(random_with_random_sign),
            texture = "^[colorize:red",
            playername = user,
            glow = 14,
        })
    end
end

minetest.register_craftitem("libox_computer:programmer", {
    description = "Laptop programmer\n" ..
        minetest.colorize("#777777",
            "All it currently does is reset the laptop/robot to the editor ui, \nand if you try to place it, it will disable the robot/laptop"),
    short_description = "Laptop programmer",
    inventory_image = "laptop_tool.png",
    stack_max = 1,
    range = 10,
    light_source = 14,
    on_use = function(_, user, pointed_thing)
        return default_on_use(user, pointed_thing)
    end,
    on_place = function(_, user, pointed_thing)
        return default_on_place(user, pointed_thing)
        -- now we also disable the sandbox when on_place
    end
})
