# Libox_computer

A mod offering
- Libox laptop
 - A sort of... luacontroller i guess you could say... with a digistuff touchscreen on top
  - Inspired by the lwcomputers mod, `but without the horrible text inputting`, and without the filesystem stuff
- Libox robot
  - Like the libox laptop, but has an inventory and can interract with the world

# Differences from luacontroller

- The sandbox is inside a *coroutine*
  - What that means is you can stop the sandbox at any time, and resume from that point
- Has the [mt-mods digistuff touchscreen protocol](https://github.com/mt-mods/digistuff/blob/master/docs/touchscreen.md) built in
- Uses libox, and environment is mostly handled by libox
  - This means you get extra stuffs to play with and also the sandbox is limited by time, not instructions

**More in [DOCS.md](https://github.com/TheEt1234/libox_computer/blob/master/DOCS.md)**

# Support

- mesecons_debug: limiting works fully because this mod uses mesecon queue, no extra things needed
- mesecons: only uses it for some utility functions (like mesecon queue and heat), doesn't support mesecons I/O (way too complicated)
- digilines: the laptop and the robot have digilines I/O
- luatool: All luatool's features are supported here
- wrench: You can pick it up with a wrench
- pipeworks: Robot uses pipeworks for inventory automation (receiving/sending items)

# Common troubleshooting
- How to get it to weigh local variables propertly/What do i do if i want this on a server
    - You need to add libox to trusted mods for it to expose and use `debug.getlocal` and `debug.getupvalue` and use those to weigh the sandbox

# What wont be happening
- mesecon interraction: i feel like it would be too complicated to rewrite the code to support that at this point
- setfenv/getfenv: i am afraid of messing that up...
- metatables: you can hide values inside them and i think `getmetatable()` is not that fast so weighing things would be slow ***(needs to be verified actually)***, and also i just feel like they can be used to do some nasty stuff

# What to report as a bug

- If it's not covered in the common troubleshooting page and feels un-intended or abusable, then please report it as a bug
- If you can hide some data inside userdata, ***it's a bug***

# Things open to discussion
- The crafing recipe **CURRENTLY LACKS A CRAFTING RECIPE**
- The defaults
- The looks
- ok really anything...