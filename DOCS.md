# so this is a little different than the luacontroller

So, yeah, what the title says it's not just a luacontroller with a touchscreen attached on it....

*Because you can `yield` here*

What that means is basically stop and resume the execution

so in a **luacontroller** you do something like this:

```lua
    if event.type == "digiline" then
        print("hello world")
    end
```

but in a **libox computer**:
```lua
    repeat
        local event = yield()
        if event.type=="digiline" then
            print("hello world")
        end
    until false -- infinite loop
```


*"interrupts"* are also done differently as well, here is in a **luacontroller**:

```lua
    if event.type=="interrupt" or event.type=="program" then
        interrupt(1, "iid")
        print("hello world")
    end
```

and here in a **libox computer**:

```lua
    repeat
        yield(1) -- this waits, ignores all events incoming
        print("hello world")
    until false
```

theese yields can also be done in any other loops

*and yes the yield function is just coroutine.yield*

***Also, yield waits aren't done lightweight-ly, they are done using mesecon queue***

# Environment
- [standard libox environment](https://github.com/TheEt1234/libox/blob/master/env_docs.md) with additions, those are described here

## `yield(command)`
when ran without arguments, it waits for an event and returns it
may be used internally by some of the commands here to provide delay

### Waiting
when ran with a number, it *waits* for the number of seconds specified, ***ignoring all events***

same thing can be achieved with:
```lua
event = yield({
    type = "wait",
    time = 0
})
```
Also, about waits: when you do yield(0) it actually gets converted to `yield(1 / (heat_max - 2))`

### Awaiting

```lua
event = yield({
    type = "await",
    time = 0
})
```
*wait* but if another event from outside gets to the sandbox, it will return that instead

<hr>

### Stopping

```lua
    event = yield({type = "stop"})
    event = yield("stop")
```
it stops the sandbox

### More yield logic maybe will get added soon!

<hr>

### The events returned

Also... yeah the event returned...
sort of like the luacontroller but still a little different

Event types: `wait`, `await`, `digiline`, `terminal`, `gui`, `error`

The error event type is returned when wrong parameters are given to the yield command

# OK now the actually new things

# gui (touchscreen_message)
- see [touchscreen docs](https://github.com/mt-mods/digistuff/blob/master/docs/touchscreen.md)

### Things that were added:
#### Formspecs
```lua
    gui({
        command = "formspec",
        text = "label[0,0;hello]"
    })
```
see [formspec docs](https://api.minetest.net/formspec/) if you have no idea what you just saw in that `text` field  

also formspecs can be more powerful than touchscreen elements

#### Lists
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

See [minetest docs](https://api.minetest.net/inventory/#inventory-locations) for info on inventory locations

#### The `gui` event type
when someone clicks on something it will send a `gui` event, where `fields` are the formspec fields, it also includes a `clicker` in the fields

also, the `hide_gui` element name is special, as it will... hide the gui (switching to the editor) when triggered  

aaalso.... there is a gui action limit to prevent the laptop from overheating... currently hardcoded to be at `heat_max - 2`

# terminal I/O

- basically the standard mooncontroller terminal I/O
- you have `print(text, dont_include_new_line)` and `clearterm()`
- oh yeah the input... if you `yield()` you can receive the `terminal` event, where its `msg` is the terminal message

# color_laptop(n) and color_robot(n)

- returns false if unsuccessful
- `n`, in the case of a laptop, is a number above 0, and less than 64
- `n`, in the case of a robot, is a number above 0, and less than 8
- it colors the laptop based on the number
- The colors are based off of the pallete defined in textures/laptop_palette.png and textures/robot_palette.png

# Other stuff

`pos` - position  
`settings` - the settings table  

`digiline_send(channel, msg)` - luacontroller's implementation but returns an error message if its not successful, and also may be configured to allow functions (that have their environment get exterminated though)  

`heat` `heat_max` - see luacontroller's `heat` and `heat_max`, if `heat` reaches above `heat_max` the libox computer will overheat

`mem` - persistant storage (across sandbox restarts/server restarts/whatever), cannot store threads, functions or userdata

# Coroutine library (coroutine.*)
- create - unchanged
- resume - Changed in the style of libox pcall (so cant nuke the hook)
- yield - unchanged, same yield as in _G

# ROBOT
- Offers an extended version of laptop's library, a huge inventory and inventory manipulation

FROM NOW ON, THIS IS ABOUT THE ROBOT 
-------------------------------------

# Inv library (inv.*)

They are limited methods of InvRef, not returning ItemStacks but their table'd versions, they are called like `a.b` not `a:b`  
Please see [InvRef docs](https://api.minetest.net/class-reference/#invref), even if this library is severely limited

- is_empty = unchanged,
- get_size = unchanged,
- get_stack = gets the table'd version of the itemstack
- get_list = gets the list of table'd versions of itemstack,

- room_for_item = unchanged,
- contains_item(stack, [match_meta]) = uncahnged


- lock = locks the inventory
- unlock = unlocks the inventory, by default the inventory is unlocked, avaliable to even client side mods *please lock your inventory if you have something going on there*

# GUI - Displaying the inventory

There are 2 methods:
- using the new formspec command:  
    ```lua
        {
            command = "formspec",
            text = "list[current_name;main;1,1;12,12;]"
        }
    ```
- using the new list command:
    ```lua
        {
            command = "add",
            element = "list",
            location = "current_name"
            name = "main", -- THIS WILL NOT GET RETURNED BY ANY FIELDS, this is the inventory name, for the robot it is main, so use main unless you are doing something crazy  
            X = 0, 
            Y = 0,
            W = 10,
            H = 10,
            start_index = 0,
 
        }

    ```

# Pipeworks support 
- Robot is allowed to take the items if pipeworks is avaliable

### Injecting items
inject_item(item, rpos)
- item, if a number will point to the index in the inventory
- item, if a string or a table, will *go thru all the slots* and attempt to find an item with the same name

- rpos, is a vector that indicates the relative coordinates of where the item will be injected in, by default `{ x = 0, y = 1, z = 0 }`, also indicates the velocity, see "Valid rposes" for more

### Valid rposes

Theese are the tables you can insert when something says it has an *rpos* argument

```lua
        { x = 1,  y = 0,  z = 0 }
        { x = -1, y = 0,  z = 0 }
        { x = 0,  y = 1,  z = 0 }
        { x = 0,  y = -1, z = 0 }
        { x = 0,  y = 0,  z = 1 }
        { x = 0,  y = 0,  z = -1 }
```
# Moving
## move(rpos)
-  rpos, is a vector that indicates the relative coordinates of where the robot will move, by default `{ x = 0, y = 1, z = 0 }` see "Valid rposes" for more  

This function is actually equal to:
```lua
    coroutine.yield({
        type = "move",
        rpos = rpos,
    })
```

It will give back a `wait` event, currently waits the amount of time set by a setting (by default 0.1)

#### Possible errors with this: (it will give back an `error` event, whose `errmsg` contains the error):

- if the target node isn't buildable to, it errors
- if the target node is ignore, it errors
- if the area is protected and not accessible by you, it errors

# node.* library (only avaliable if pipeworks are supported)

All positions are relative, in a range defined in settings (by default 30)

- `is_protected(pos[, owner])` - owner is optional, checks if an area is protected
- `get(pos)` - get a node

Now, theese functions, if unsuccessful return a string, else they yield, then return a wait event  
By default they wait 0.1 seconds, can be changed with the place/drop delay setting  
The `pos` argument of theese functions is relative

- `place(pos, name[, def])` - def is optional, places an item/node at that relative position, `def` contains `param2` and `up` or `down` or `west` or `east` or `auto`
- `dig(pos, name)` - digs a node with a tool (the tool's name is in... name), does not wear out the tool, ***IGNORES THE SETTING, INSTEAD WAITING THE AMOUNT OF TIME IT TAKES TO BREAK THE NODE***
- `drop(pos, name)` - drops a node
### If you are worried about lag:

- all the node.* functions get accounted for their lag, so it respects the 3ms limit

### If you are worried about balance:
- You can set a setting that will force the world modifying functions to wait more
- The dig_node function will *always* wait the amount of time the tool takes to destroy the node, keep that in mind *when limiting the other actions..., so don't make placing take 2x more as digging... :>*
- if you are worried that the robot makes all of pipeworks into one funny flying lua controlled node then.... i mean fair *but it sure is fun* and i think thats all what we care about right

# What to report as a bug

- If it's not covered in the common troubleshooting page, then please report it as a bug
- Also, if you can hide and retrieve some data inside a userdata object or a metatable, ***it's a bug***
- if you obtain the ItemStack userdata, ***it's a bug***

# Common troubleshooting
- It says i need this mystery libox thing, it doesn't appear in minetest mod search
    - libox is not yet uploaded to contentDB, in the meantime download it from [here](https://github.com/TheEt1234/libox)
- The sandbox doesn't weigh local variables
    - You need to add libox to trusted mods for it to expose and use `debug.getlocal` and `debug.getupvalue`

# What wont be happening
- mesecon interraction: why mesecon when you can digi
- ports/pins: would severely overcomplicate things, maybe ""fake"" ports could be implemented if you think a direction vector looks intimidating
- setfenv/getfenv: i am afraid of messing that up...
- metatables: you can hide values inside them, oh and `getmetatable()` is not that fast to weigh things (needs to be verified actually), and also they just feel like they can be used to do some nasty stuff