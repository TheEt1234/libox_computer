# Libox_computer

A mod offering:
  - Libox laptop: a mix of mooncontroller, digistuff touchscreen and libox coroutine sandboxes
  - Libox robot: Libox laptop but can move and interract with pipeworks
  - Laptop programmer: when clicked on a robot/laptop it will restore the original programming UI, when shift+right clicked it will stop the robot/laptop
see DOCS.md for actual documentation and introduction

# Support/Dependancies

- mesecons_debug: one of the main things it does is limit mesecon queue, libox_computer does use mesecon queue so it is compatible, and this mod doesn't need to even optionally depend on it
- mesecons: the libox_computer mod does not interface with mesecons in an obvious way but it relies on functions from it (like the mesecon queue mentioned earlier)
- digilines: the laptop has digilines I/O
- it also depends on [libox](https://github.com/TheEt1234/libox) for the coroutine sandboxing
  - optionally, not so much if you are a server... you can make libox a trusted mod and it will weigh the local variables and upvalues of the coroutine

## Robot's depends

- pipeworks: everybody uses them and its perfect for me so... also without pipeworks the robot cant perform node modifying actions (relies on fake player) and injecting items
# License/credits

- Code (Unless stated otherwise) - LGPLv3

- Inspiration - [LWcomputers](https://github.com/loosewheel/lwcomputers/) (but today lwcomputers is abadoned and filled with ways to bypass the instruction limit)

- robot_actions.lua - based off digibuilder and pipeworks way of doing things (pipeworks is licensed under LGPLv3, while digibuilder is licensed under MIT)
- Ui - based off mooncontroller's ui - [mooncontroller's ui.lua](https://github.com/mt-mods/mooncontroller/blob/master/ui.lua) - LGPLv3
- touchscreen_protocol.lua - LGPLv3 - [see mt-mods's digistuff](https://github.com/mt-mods/digistuff/tree/master)
Textures 
- laptop_ui_bg.png laptop_ui_run.png - CC-BY-SA 3.0 [luacontroller textures here!](https://github.com/minetest-mods/mesecons/tree/master/mesecons_luacontroller/textures)
- laptop_palette.png - Shrunk down version of unifieddyes_palette_extended.png, unified dyes is licensed under GPLv2


# Todos (not in order)

- better code
- T E S T S
- maybe more robot features
