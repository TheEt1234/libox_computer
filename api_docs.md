# Api docs for an api that you aren't reaallly supposed to use but can
# If you want to know how to actually program theese nodes, see DOCS.md

# If you want to know how this mod works, then yeah this may be for you

All the guts of the mod are located inside the `libox_computer` table


# Absolutely irrelevant stuff

**libox_computer.basename_laptop** - the name of the laptop node  
**libox_computer.basename_robot** - the name of the robot node  
**libox_computer.is_from_mod** - a lookup table for the laptop tool to identify what it can touch  
**libox_computer.settings** - a table for the settings

# Touchscreen protocol
Guts in `libox_computer.touchscreen_protocol`, i am not gonna document them, they aren't all used, just some are

# Utilities - a fancy name for *random stuff*
- **libox_computer.digiline_wrap(f)** - remove the environment of the function, used when sending/receiving digilines messages (to not allow funky communication), id say dont use this in your mod as i may change my mind about this if i dont find any exploits
- **libox_computer.raw_print(meta, text)** - prints to the terminal something, doesn't do any validation
- **libox_computer.report_error(meta, text, preceeding_text)** - reports... an error... to the terminal, and also to the errmsg meta
- **libox_computer.get_digiline_send(pos)** -- get the digiline_send function
- **libox_computer.get_print(meta) -- from mooncontroller** - get the print() function for any libox computer sandbox
- **libox_computer.get_clearterm(meta)** - gets a function that clears the terminal, used in libox computer sandboxes

# Sandboxes
- **libox_computer.sandbox.create_laptop_environment(pos)** - creates a laptop environment for `pos`
- **libox_computer.sandbox.create_robot_environment(pos)** - same thing but for the robot
- **libox_computer.sandbox.create_sandbox(pos)** - ***creates*** the sandbox, does not run it, does not return an error
- **libox_computer.sandbox.save_mem(meta, mem)** - saves the memory, i don't know if its vurnable to that mesecons bug (https://github.com/minetest-mods/mesecons/issues/415)

### **libox_computer.sandbox.yield_logic_funcs**
so i am crap at explaining things so here have an example:
```lua
    {
        stop = { 
            types = {},
            f = function(_, meta, id)
                libox_computer.report_error(meta, "Sandbox stopped.")
                libox.coroutine.active_sandboxes[id] = nil
            end
        },
        wait = {
            types = {
                time = "number"
            },
            f = function(pos, meta, id, args)
                local time = args.time
                time = math.max(settings.min_delay, time)
                meta:set_int("is_waiting", 1) -- ignore all incoming events
                mesecon.queue:add_action(pos, "lb_wait", { id }, time, id, 1)
            end
        }
        -- .... and more
    }
```

# Back to the sandboxes section
- **libox_computer.sandbox.run_sandbox(pos, event)** - *runs a sandbox*
- **libox_computer.sandbox.wake_up_and_run(pos, event)** - *creates and runs a sandbox, enforces that delay*

# Mesecon queue functions
- `<queue>` - mystery mesecon queue function store, functions are supposed to be called with `mesecon.queue.add_action`
- `<queue>.lb_wait(pos, id)` - resumes a sandbox with a wait event
- `<queue>.lb_err(pos, id, errmsg)` - resumes a sandbox with an error event
- `<queue>.lb_await(pos, id)` - resumes a sandbox with an *await* event (timed)
- `<queue>.lb_digiline_relay(pos, channel, msg)` - sends a digiline message

# Robot actions
- all nil if fakelib is not found
- `local f = libox_computer.get_place(robot_pos, inv, owner)`
- `local f = libox_computer.get_break(robot_pos, inv, owner)`
- `local f = libox_computer.get_drop(robot_pos, inv, owner)`

# the frontend
- `ui(meta)`
- `on_receive_fields(pos, _, fields, sender)`

# i think thats all thats relevant :D
