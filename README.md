# Libox_computer

basically a mooncontroller + digilines touchscreen + libox coroutine sandboxes

see DOCS.md for actual documentation and introduction

# Support/(optional) Dependancies

- mesecons_debug: one of the main things it does is limit mesecon queue, libox_computer does use mesecon queue so it is compatible
- mesecons: the libox_computer mod does not interface with mesecons in an obvious way but it relies on functions from it (like the mesecon queue mentioned earlier)
- digilines: the laptop has digilines I/O
- it also depends on [libox](https://github.com/TheEt1234/libox) for the coroutine sandboxing
 - optionally, not so much if you are a server... you can make libox a trusted mod and it will weigh the local variables and upvalues of the coroutine

# License

Code - LGPLv3  
Inspiration - [LWcomputers](https://github.com/loosewheel/lwcomputers/) (but today lwcomputers is abadoned and filled with ways to bypass the time limit)
*Some of the code has been based off of mooncontroller*

- Ui - based off mooncontroller's ui - [mooncontroller's ui.lua](https://github.com/mt-mods/mooncontroller/blob/master/ui.lua)
Textures 
- laptop_ui_bg.png laptop_ui_run.png - CC-BY-SA 3.0 [luacontroller textures here!](https://github.com/minetest-mods/mesecons/tree/master/mesecons_luacontroller/textures)
- touchscreen_protocol.lua - LGPLv3 - [mt-mods's digistuff](https://github.com/mt-mods/digistuff/tree/master)
- laptop_palette.png - Shrunk down version of unifieddyes_palette_extended.png, GPLv2

# Todos (not in order)

- more environment stuffs maybe?
- T E S T S
- maybe robots?
