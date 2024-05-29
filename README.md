# Libox_computer

A mod offering
- Libox laptop
  - A sort of... luacontroller i guess you could say... with a digistuff touchscreen on top
  - Inspired by the lwcomputers mod, `but without the horrible text inputting` and filesystem stuff, you can code that stuff
- Libox robot
  - Like the libox laptop, but has an inventory and can interract with the world

# Differences from luacontroller

- The sandbox is inside a *coroutine*
  - What that means is you can stop the sandbox at any time, and resume from that point
  - This is how the libox computer handles events
  - When the sandbox errors or stops, it dies
- If the sandbox is not found (say, during a digiline or a gui event) then it will "wake up"
  - What that means is it will start the sandbox again, `mem` will still be kept as it was before, you can't kill and start sandboxes in a short time frame, limit is configured by settings
- Has the [digistuff touchscreen protocol](https://github.com/mt-mods/digistuff/blob/master/docs/touchscreen.md) built in
  - And has even some extra commands
- Uses libox, and environment is mostly handled by libox
  - This means you get extra stuffs to play with and also the sandbox is limited by time, not instructions
- Attempts to do coroutine sandboxes securely
  - But minetest mod security doesn't allow us to weigh the local variables and upvalues of the environment, so libox needs to be a trusted mod for that to work (optional)


**More in [DOCS.md](https://github.com/TheEt1234/libox_computer/blob/master/DOCS.md)**

# Support

- mesecons_debug: limiting works fully because this mod uses mesecon queue, no extra things needed
- mesecons: only uses it for some utility functions (like mesecon queue and heat), doesn't support mesecons I/O
- digilines: the laptop has digilines I/O
- luatool: All luatool's features are supported here
- wrench: You can pick it up with a wrench
- pipeworks: Robot uses pipeworks for inventory automation (receiving/sending items)

### This mod uses code from other mods, see [LICENSE.md](https://github.com/TheEt1234/libox_computer/blob/master/LICENSE.md)


# Todos (not in order)

- better code
- T E S T S
- maybe more robot features (autocrafting :?)


# Common troubleshooting
- The sandbox doesn't weigh local variables
    - You need to add libox to trusted mods for it to expose and use `debug.getlocal` and `debug.getupvalue` and use those to weigh the sandbox

# What wont be happening
- mesecon interraction: i feel like it would be too complicated to rewrite the code to support that at this point
- setfenv/getfenv: i am afraid of messing that up... like that could lead to some actual full minetest server control
- metatables: you can hide values inside them, oh and `getmetatable()` is not that fast so weighing things would be slow *(needs to be verified actually)*, and also i just feel like they can be used to do some nasty stuff

# What to report as a bug

- If it's not covered in the common troubleshooting page and feels un-intended or abusable, then please report it as a bug
- If you can hide some data inside userdata, ***it's a bug***
    - if you obtain userdata that you can write unlimited data to directly, it's probably a bug

# Things open to discussion
- The crafing recipe **CURRENTLY LACKS A CRAFTING RECIPE**
- The defaults
- The looks
- ok really anything...