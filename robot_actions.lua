--[[
    Stupidly complex
    Minetest is hell....
]]

if not minetest.global_exists("pipeworks") then
    return false -- cannot operate without pipeworks:create_fake_player
    -- alternative: scan all of _G for a function named create_fake_player
end

-- straight out of pipeworks
local can_tool_dig_node = function(nodename, toolcaps)
    local nodedef = minetest.registered_nodes[nodename]
    -- don't explode due to nil def in event of unknown node!
    if (nodedef == nil) then return false end

    local nodegroups = nodedef.groups
    local dig_params = minetest.get_dig_params(nodegroups, toolcaps)
    if not dig_params.diggable then
        -- a pickaxe can't actually dig leaves based on it's groups alone,
        -- but a player holding one can - the game seems to fall back to the hand.
        -- fall back to checking the hand's properties if the tool isn't the correct one.
        local hand_caps = minetest.registered_items[""].tool_capabilities
        dig_params = minetest.get_dig_params(nodegroups, hand_caps)
    end
    return dig_params
end

local function best_inventory_index(inv, itemname)
    if not inv:contains_item("main", itemname) then
        return nil
    end

    local best_stack, best_index, stack
    local list = inv:get_list("main")
    local index = #list
    repeat
        stack = list[index]
        if not stack:is_empty() then
            if itemname == stack:get_name() then
                if not best_stack then
                    best_stack = stack
                    best_index = index
                elseif (best_stack:get_wear() == 0 and stack:get_wear() > 0)
                    or (best_stack:get_wear() > stack:get_wear() and stack:get_wear() > 0) then
                    best_stack = stack
                    best_index = index
                end
            end
        end
        index = index - 1
    until index == 0

    return best_index
end

local function return_stack(pos, inv, stack)
    if stack:is_empty() then return end
    local overflow_stack = inv:add_item("main", stack)
    if not overflow_stack:is_empty() then
        -- TODO: discuss if items should be dropped at absolute_pos or pos
        minetest.add_item(pos, overflow_stack)
    end
end

local settings = libox_computer.settings
local function is_vector_within_range(vec)
    return vector.in_area(vec, {
        x = -settings.range,
        y = -settings.range,
        z = -settings.range
    }, {
        x = settings.range,
        y = settings.range,
        z = settings.range
    })
end

function libox_computer.get_place(pos, meta, inv, owner)
    return function(vec, name, def)
        if not is_vector_within_range(vec) then
            return "Vector not in range."
        end


        local absolute_pos = pos + vec

        if minetest.is_protected(absolute_pos, owner) then
            return "That area is protected"
        end

        if type(name) ~= "string" then return "Invalid item" end
        local index = best_inventory_index(inv, name)
        if index == nil then
            return "Item not found"
        end

        local node = minetest.get_node(absolute_pos)

        local node_def = minetest.registered_nodes[node.name]
        if not node_def then
            return "Target unknown"
        end
        if not node_def.buildable_to then
            return "Target not buildable to"
        end

        local place_node_def = minetest.registered_items[name]
        if not place_node_def then
            return "Node/item unknown"
        end

        if not place_node_def.on_place then
            return "Can't place that"
        end

        local place_node = {
            name = name,
        }

        if type(def) == "table" then
            local param2 = tonumber(def.param2) or 0
            param2 = math.min(param2, 255)
            param2 = math.max(param2, 0)
            place_node.param2 = param2 -- let the user choose arbitrary param2
        end

        if place_node.param2 == nil then
            place_node.param2 = place_node_def.param2
        end

        -- so... we are not gonna do fancy directional crap because... there are way too many paramtypes for direction
        -- color4dir, 4dir, colorfacedir, facedir, degrotate, colordegrotate

        -- so yeah screw that (how would i do degrotate anyway)

        local player = pipeworks.create_fake_player({
            name = owner,
            inventory = inv,
            wield_list = "main",
            wield_index = index,
            position = vector.subtract(absolute_pos, vector.new(0, 1.5, 0)),
        })

        local pointed_thing = {
            type = "node",
            above = vector.copy(absolute_pos),
            under = vector.copy(absolute_pos)
        }

        if type(def) == "table" then
            if def.up == true then
                pointed_thing.under.y = absolute_pos.y + 1
            elseif def.down == true then
                pointed_thing.under.y = absolute_pos.y - 1
            elseif def.west == true then
                pointed_thing.under.x = absolute_pos.x - 1
            elseif def.east == true then
                pointed_thing.under.x = absolute_pos.x + 1
            elseif def.south == true then
                pointed_thing.under.z = absolute_pos.z - 1
            elseif def.north == true then
                pointed_thing.under.z = absolute_pos.z + 1
            elseif def.auto == true then
                if place_node_def.paramtype2 == "facedir" then
                    pointed_thing.under = vector.add(absolute_pos, minetest.facedir_to_dir(place_node.param2))
                elseif place_node_def.paramtype2 == "wallmounted" then
                    pointed_thing.under = vector.add(absolute_pos, minetest.wallmounted_to_dir(place_node.param2))
                else
                    pointed_thing.under.y = absolute_pos.y - 1
                end
            end
        end

        local itemstack
        local success = false
        local returnstack
        if place_node_def.on_place ~= minetest.item_place then
            -- non-default item placement, use custom function (crops, other items)
            -- taking an actual item instead of creating a new stack,
            -- raises the chances that we get something useful

            itemstack = inv:get_stack("main", index)
            inv:set_stack("main", index, ItemStack(""))
            returnstack, success = place_node_def.on_place(ItemStack(itemstack), player, pointed_thing)
            if returnstack then
                return_stack(pos, inv, returnstack)
                if returnstack:get_wear() ~= itemstack:get_wear()
                    or returnstack:get_name() ~= itemstack:get_name()
                    or returnstack:get_count() < itemstack:get_count() then
                    success = true
                end
            end
            if not success then
                if not returnstack then
                    return_stack(pos, inv, itemstack)
                end
                return "Item placement failed"
            end
        else
            -- default on_place, use `set_node` to avoid side-effects (on-place rotations)
            minetest.set_node(absolute_pos, place_node)
            inv:remove_item("main", name) -- if you are in creative this doesn't do anything??
        end

        if place_node_def.after_place_node then
            place_node_def.after_place_node(absolute_pos, player, ItemStack(), pointed_thing)
        end

        minetest.check_for_falling(absolute_pos)

        local check_node = minetest.get_node(absolute_pos)
        -- it is not always a bad sign when name of placed node does
        -- not match itemname, certain nodes change their name (or fall)
        -- also itemname and nodename don't always match
        if check_node.name == name and check_node.param2 ~= place_node.param2 then
            -- enforce param2
            minetest.swap_node(absolute_pos, place_node)
        end

        return coroutine.yield({
            type = "wait",
            time = settings.set_node_delay
        })
    end
end

--[[
    Now that we've got the place behaviour..... AAAAAAAAAAAAAA
    okay we seriously need a unified library for all this....
]]
function libox_computer.get_break(pos, meta, inv, owner)
    return function(vec, name)
        -- name is the name of the tool
        if not is_vector_within_range(vec) then
            return "Vector not in range."
        end

        local absolute_pos = pos + vec

        if minetest.is_protected(absolute_pos, owner) then
            return "That area is protected"
        end

        if type(name) ~= "string" then return "Invalid item" end
        local index = best_inventory_index(inv, name)
        if index == nil then
            return "Item not found"
        end

        local tool = inv:get_stack("main", index)
        local old_tool_stack = ItemStack(tool)
        local node = minetest.get_node(absolute_pos)

        local node_def = minetest.registered_nodes[node.name]
        if not node_def then
            return "Target unknown"
        end

        if not node_def.on_dig then
            return "Can't dig that node (missing on_dig)"
        end

        local player = pipeworks.create_fake_player({
            name = owner,
            inventory = inv,
            wield_list = "main",
            wield_index = index,
            position = vector.subtract(absolute_pos, vector.new(0, 1.5, 0)),
        })

        local dig_params = can_tool_dig_node(node.name, tool:get_tool_capabilities(), tool:get_name())
        if dig_params and dig_params.diggable then
            node_def.on_dig(absolute_pos, node, player)
        else
            return "Can't dig that node"
        end

        local wieldname = tool:get_name()
        if wieldname == old_tool_stack:get_name() then
            if tool:get_count() == tool:get_count() and
                tool:get_metadata() == tool:get_metadata() and
                ((minetest.registered_items[tool:get_name()] or {}).wear_represents or "mechanical_wear") == "mechanical_wear" then
                inv:set_stack("main", index, old_tool_stack)
            end
        elseif wieldname ~= "" then
            -- "tool got replaced?"
            -- "nahh its a drop"
            -- - pipeworks
            -- probably i should stick with that
            return_stack(pos, inv, overflow)
        end

        return coroutine.yield({
            type = "wait",
            time = dig_params.time or settings.set_node_delay
        })
    end
end

function libox_computer.get_drop(pos, meta, inv, owner)
    return function(vec, name)
        if not is_vector_within_range(vec) then
            return "Vector not in range."
        end

        local absolute_pos = pos + vec

        if minetest.is_protected(absolute_pos, owner) then
            return "That area is protected"
        end

        if type(name) ~= "string" then return "Invalid item" end
        local index = best_inventory_index(inv, name)
        if index == nil then
            return "Item not found"
        end

        local item_def = minetest.registered_items[name]
        if item_def == nil then
            return "Unknown item."
        end
        if not item_def.on_drop then
            return "Can't drop this item (no on_drop)."
        end

        local player = pipeworks.create_fake_player({
            name = owner,
            inventory = inv,
            wield_list = "main",
            wield_index = index,
            position = vector.subtract(absolute_pos, vector.new(0, 1.5, 0)),
        })

        local stack = item_def.on_drop(inv:get_stack("main", index), player, absolute_pos)
        inv:set_stack("main", index, stack)

        return coroutine.yield({
            type = "wait",
            time = settings.set_node_delay
        })
    end
end
