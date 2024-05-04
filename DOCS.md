# hey this is a little different than the luacontroller

So, yeah, what the title says it's not just a luacontroller with a touchscreen attached on it....

*Because you can `yield` here*

What that means is basically stop and resume the execution

so in a **luacontroller** you do something like this:

```lua
    if event.type == "digiline" then
        print("h")
    end
```

but in a **libox computer**:
```lua
    repeat
        local event = yield()
        if event.type=="digiline" then
            print("h")
        end
    until false -- infinite loop
```


*"interrupts"* are also done differently as well, here is in a **luacontroller**:

```lua
    if event.type=="interrupt" or event.type=="program" then
        interrupt(1, "iid")
        print("h")
    end
```

and here in a **libox computer**:

```lua
    repeat
        yield(1)
        print("h")
    until false
```

theese yields can also be done in any other loops

*and yes the yield function is just coroutine.yield*

***Also, yield waits aren't done lightweight-ly, they are done using mesecon queue***

# Environment
- standard libox environment (see with `print(_G)`)

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

# terminal I/O
- basically the standard mooncontroller terminal I/O
- you have `print(text, dont_include_new_line)` and `clearterm()`
- oh yeah the input... if you `yield()` you can receive the `terminal` event, where its `msg` is the terminal message

# color_laptop(n)
- returns false if unsuccessful
- `n` is a number above 0, and less than 16
- it colors the laptop based on the number
- "What color is what number" great question... that is an excercise for the viewer......
- TODO: trivially pack 2x more colors into this

# Other stuff
`pos` - position  
`settings` - the settings table  

`digiline_send(channel, msg)` - luacontroller `digiline_send(channel, msg)` but returns an error message if its not successful, and also may be configured to allow functions (that have their environment get exterminated though)  

`heat` `heat_max` - see luacontroller's `heat` and `heat_max`, if `heat` reaches above `heat_max` the libox computer will overheat