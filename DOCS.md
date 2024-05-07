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

when ran with a number, it *waits* for the number of seconds specified, ***ignoring all events***

same thing can be achieved with:
```lua
event = yield({
    type = "wait",
    time = 0
})
```


Also, about waits: when you do yield(0) it actually gets converted to `yield(1 / (heat_max - 2))`

<hr>

```lua
event = yield({
    type = "await",
    time = 0
})
```
*wait* but accounts for events, without `time` argument, its equivilent to `event = yield()`
<hr>

```lua
    event = yield({type = "stop"})
```
it stops the sandbox

#### More yield logic maybe will get added soon!

<hr>

Also... yeah the event returned...
sort of like the luacontroller but still a little different

Event types: `wait`, `await`, `digiline`, `terminal`, `gui`

# gui (touchscreen_message)
- see [touchscreen docs](https://github.com/mt-mods/digistuff/blob/master/docs/touchscreen.md)

the only thing that was added was the `formspec` command
```lua
    gui({
        command = "formspec",
        text = "label[0,0;hello]"
    })
```
see [formspec docs](https://api.minetest.net/formspec/) if you have no idea what you just saw in that `text` field  

also formspecs can be more powerful than touchscreen elements

when someone clicks on something it will send a `gui` event, where `fields` are the formspec fields, it also includes a `clicker` in the fields

also, the `hide_gui` element name is special, as it will... hide the gui (switching to the editor) when triggered  

aaalso.... there is a gui action limit to prevent the laptop from overheating... currently hardcoded to be at `heat_max - 2`
in the meantime you can like... `yield(5)` or something idk up to you

# terminal I/O
- basically the standard mooncontroller terminal I/O
- you have `print(text, dont_include_new_line)` and `clearterm()`
- oh yeah the input... if you `yield()` you can receive the `terminal` event, where its `msg` is the terminal message

# color_laptop(n)

- returns false if unsuccessful
- `n` is a number above 0, and less than 64
- it colors the laptop based on the number
- The colors are based off of the pallete defined in textures/laptop_palette.png 

# Other stuff

`pos` - position  
`settings` - the settings table  

`digiline_send(channel, msg)` - luacontroller's implementation but returns an error message if its not successful, and also may be configured to allow functions (that have their environment get exterminated though)  

`heat` `heat_max` - see luacontroller's `heat` and `heat_max`, if `heat` reaches above `heat_max` the libox computer will overheat

`mem` - persistant storage (across sandbox restarts/server restarts/whatever), cannot store threads, functions or userdata

# Coroutine library (coroutine.*)
- create - unchanged
- resume - Changed in the style of libox pcall
- yield - unchanged, same yield as in _G

# ROBOT
- Offers an extended version of laptop's library, a huge inventory and inventory manipulation
- Changes: `color_laptop(n) -> color_robot(n)`, robot only supports 8 colors

== FROM NOW ON, THIS IS ABOUT THE ROBOT ==

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
- formspecs:  
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

# Pipeworks support - injecting items

inject_item(item, rpos)
- item, if a number will point to the index in the inventory
- item, if a string or a table, will *go thru all the slots* and attempt to find an item with the same name

- rpos, is a vector that indicates the relative coordinates of where the item will be injected in, by default `{ x = 0, y = 1, z = 0 }`, also indicates the velocity

