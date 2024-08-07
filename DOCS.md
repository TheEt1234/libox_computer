# So... you code a little differently here...

You can stop the sandbox at any time, that means if you run this code:
```lua
function really_expensive_function()
    for i=1,10000 do
        if i%1000 == 0 then
            _event = yield(0) -- wait the minimum amount of time allowed
            -- _event is a useless wait event
            -- the sandbox pauses for a small amount of time
        end
    end
    return ":D"
end
print(really_expensive_function())
```
You will get a `:D` in the terminal  

This is how you do events actually...
```lua
while true do
    event = yield() -- when ran without arguments, it will wait for an event, then return it
    ....your code stuff
end
```

### also we get a yucky with a JIT vs PUC lua difference...

luaJIT claims to be fully resumable  
"The LuaJIT VM is fully resumable. This means you can yield from a coroutine even across contexts, where this would not possible with the standard Lua 5.1 VM: e.g. you can yield across pcall() and xpcall(), across iterators and across metamethods. " - https://luajit.org/extensions.html

But Normal lua might not be... **libox_computer has not been tested with a minetest non-luajit build, thus not officially supported**

TL;DR you can *pause* the sandbox using the `yield` function, then it starts again, and that is the way you get events (`event = yield()`)
 

## Definitions

"waking up the sandbox" - sandbox will get created, this has a limit of 5 seconds by default, the `program` button bypasses it

"overheat the sandbox" - it doesn't actually render the robot completely useless (like in normal luacontrollers), but rather just stops the sandbox, usually caused by external things like digilines, and rarely yield waiting

"limit" - The sandbox has a time/memory limit

"digistuff" - i am not refering to abadoned chiepie's (the one that's on contentDB) digistuff here, i am referring to the mt-mods's fork of digistuff, that you can find [here](https://github.com/mt-mods/digistuff)

# What does the libox computer tool do?
- when you click it on a laptop/computer it turns it off forcefully

# Environment (the stuffs you get to play with)

Has the [standard libox environment](https://github.com/TheEt1234/libox/blob/master/env_docs.md) with additions, those additions are described here

# More into the yield function...


**`event = yield()`**  
- it waits for an event and returns it

<hr>

**`yield(n)`**  
```lua
yield({
    type = "wait",
    time = n
})
```  
- Pauses the sandbox for  `n` amount of seconds

- **all events get ignored**

- The event returned is just a table that looks like: `{ type = "wait" }`
- The lower limit on yielding is `1 / (heat_max - 2)`
- The waiting is done using mesecon queue, not node timers

<hr>

```lua
event = yield({
    type = "await",
    time = 0
})
```
- identical to the `wait` command, but **doesn't ignore events**
- Event returned is a `wait` event, or a normal event

<hr>

**`yield(stop)`**
- it *stops* the sandbox...

# The events returned

Event types: `wait`, `await`, `digiline`, `terminal`, `gui`, `error`

## Error event

The error event type is returned when wrong parameters are given to a yield command, looks something like this:

```lua
    {
        type = "error",
        errmsg = "any string :D"
    }
```

## Gui event

Happens when someone clicks something on the gui, the event is limited so that someone spam clicking cannot overheat your sandbox (the gui action limit is `heat_max - 2` per second), looks something like this:

```lua
    {
        type = "gui",
        fields = {
            -- There are more fields than this, but the clicker field is guaranteed, the fields are the fields sent to on_receive_fields, see the minetest documentation for minetest.register_on_player_receive_fields
            clicker = "any player name"
        }
    }
```

## Terminal event

Happens when someone clicks send in the terminal tab, looks something like this:

```lua
    {
        type = "terminal",
        msg = "Any message, can even contain new lines actually but don't rely on that"
    }
```

# Now some functions

## `gui(touchscreen_message)`
- see the [touchscreen protocol docs](https://github.com/mt-mods/digistuff/blob/master/docs/touchscreen.md)
- but there were some things added to the touchscreen protocol to make it better for robots

##### **Additions:**

**Formspecs**

```lua
    gui({
        command = "formspec",
        text = "label[0,0;hello]"
    })
```
- Adds the specified formspec to the gui  
see [formspec docs](https://api.minetest.net/formspec/) if you have no idea what you just saw in that `text` field  

**Lists**

```lua
gui({
    command = "add",
    element = "list",
    location = "current_player",
    name = "main",
    start_index = 0,
    X = 0, Y = 0, W = 10, H = 10
})
```

- Adds a list to the gui
- location: See [minetest docs](https://api.minetest.net/inventory/#inventory-locations) for info on inventory locations
- name: *not* the elemt name, but it is the name of the inventory, `main` is also the name of the robot's chest inventory
- W,H are in item size, not real size


also, the `hide_gui` element name is special, as it will... hide the gui (switching to the editor) when triggered  


# terminal I/O

basically the standard mooncontroller terminal I/O  

You have:
`print(text, dont_include_new_line)` - prints the text into the terminal  
`clearterm()` - clears the terminal

if you `yield()` you can receive the `terminal` event, where `msg` is the message sent to the terminal

# `color_laptop(n)` and `color_robot(n)`

- returns false if unsuccessful
- `n`, in the case of a **laptop**, is a number above 0, and less than 64
- `n`, in the case of a **robot**, is a number above 0, and less than 8
- it colors the robot/laptop based on the number
- The colors are based off of the pallete defined in `textures/laptop_palette.png` and `textures/robot_palette.png`

# Other stuff (the things you are used to)

`pos` - position  
`settings` - the settings table  

`digiline_send(channel, msg)` - luacontroller's implementation but returns an error message if its not successful, and also may be configured to allow functions (that have their environment get exterminated though)  

`heat` `heat_max` - see luacontroller's `heat` and `heat_max`, if `heat` reaches above `heat_max` the sandbox will overheat

`mem` - persistant storage (across sandbox restarts/server restarts/whatever), cannot store threads, functions or userdata


# ROBOT

Offers an extended version of laptop's library, a huge inventory and inventory manipulation

FROM NOW ON, THIS IS ABOUT THE ROBOT 
-------------------------------------

# Inv library (inv.*)

They are limited methods of InvRef, not returning ItemStacks but their table'd versions, they are called like `a.b` not `a:b`  
Please see [InvRef docs](https://api.minetest.net/class-reference/#invref), even if this library is severely limited

`inv.is_empty()` = unchanged  
`inv.get_size()` = unchanged  
`inv.get_stack(i)` = gets the table'd version of the itemstack  
`inv.get_list()` = gets the list of table'd versions of itemstack  

- `inv.room_for_item(stack)` = unchanged
- `inv.contains_item(stack, [match_meta])` = uncahnged


- `inv.lock()` = locks the inventory
- `inv.unlock()` = unlocks the inventory, by default the inventory is unlocked, ***please lock your inventory if you have something going on there, if you don't, even if no inventory list is visible you can still get robbed***

# Pipeworks support 
- Robot is allowed to take the items if pipeworks is avaliable

**`inject_item(item, rpos)`**  
- item, if a number will point to the index in the inventory
- item, if a string or a table, will *go thru all the slots* and attempt to find an item with the same name

# *what is that rpos argument*
- its meant to be a direction
- here are the valid tables that you can supply to it:
- and yes the `directions` table is in your environment

```lua
    _G.directions = {
        EAST = { x = 1,  y = 0,  z = 0 },
        WEST = { x = -1, y = 0,  z = 0 },

        UP = { x = 0,  y = 1,  z = 0 },
        DOWN = { x = 0,  y = -1, z = 0 },

        NORTH = { x = 0,  y = 0,  z = 1 },
        SOUTH = { x = 0,  y = 0,  z = -1 }
    }
```

# Moving
## `move(rpos)`

Also you can do this too with:
```lua
    yield({
        type = "move",
        rpos = rpos,
    })
```

It will give back a `wait` event, currently waits the amount of time set by a setting (by default 0.1)

#### Possible errors with the move command: (it will give back an `error` event, whose `errmsg` contains the error):

- if the target node isn't buildable to, it errors
- if the target node is ignore, it errors
- if the area is protected and not accessible by you, it errors

# node.* library (only avaliable if you have fakelib)

All positions are relative, in a range defined in settings (by default 30)

- `is_protected(pos[, owner])` - owner is optional, checks if an area is protected
- `get(pos)` - get a node

<hr>
Functions below, if unsuccessful return a string, else they yield, then return a wait event  
By default they wait 0.1 seconds, can be changed with the place/drop delay setting  
The `pos` argument of theese functions is relative

- `place(pos, name[, def])` - def is optional, places an item/node at that relative position, `def` contains `param2` and `up` or `down` or `west` or `east` or `auto`
- `dig(pos, tool_name)` - digs a node with a tool, does not wear out the tool, ignores the place/drop setting, instead it waits the time it takes to break the node with the tool
- `drop(pos, name)` - drops a node


# Do you have suggestions?
please let me know