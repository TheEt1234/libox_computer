# Libox_computer

basically a mooncontroller + digilines touchscreen + libox coroutine sandboxes

see DOCS.md for actual documentation and introduction

# Support/(optional) Dependancies

- mesecons_debug: one of the main things it does is limit mesecon queue, libox_computer does use mesecon queue so it is compatible
- mesecons: the libox_computer mod does not interface with mesecons in an obvious way but it relies on functions from it (like the mesecon queue mentioned earlier)
- digilines: the laptop has digilines I/O
- it also depends on [libox](https://github.com/TheEt1234/libox) for the coroutine sandboxing
 - optionally, not so much if you are a server... you can make libox a trusted mod and it will weigh the local variables and upvalues of the coroutine

## Robot's depends

- pipeworks: `while i dont like pipeworks (autocrafters feel horrible to use when doing multi-ingredient stuff, has all theese liquid pipes whose only use is proabbly griefing and SOMEHOW they existed for more than 7 YEARS WITHOUT A GOOD USE, not even joking) they are mostly fine...` everybody uses them and its perfect for me so...

# License

Code - LGPLv3  
Inspiration - [LWcomputers](https://github.com/loosewheel/lwcomputers/) (but today lwcomputers is abadoned and filled with ways to bypass the time limit)
*Some of the code has been based off of mooncontroller*

- robot_actions.lua - based off digibuilder and pipeworks way of doing things
- Ui - based off mooncontroller's ui - [mooncontroller's ui.lua](https://github.com/mt-mods/mooncontroller/blob/master/ui.lua)
- touchscreen_protocol.lua - LGPLv3 - [mt-mods's digistuff](https://github.com/mt-mods/digistuff/tree/master)
Textures 
- laptop_ui_bg.png laptop_ui_run.png - CC-BY-SA 3.0 [luacontroller textures here!](https://github.com/minetest-mods/mesecons/tree/master/mesecons_luacontroller/textures)
- laptop_palette.png - Shrunk down version of unifieddyes_palette_extended.png, GPLv2


# Todos (not in order)

- T E S T S
- maybe more robot features