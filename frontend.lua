local escape = minetest.formspec_escape

local function ui(meta)
    local code = escape(meta:get_string("code"))
    local errmsg = escape(meta:get_string("errmsg"))
    if (errmsg ~= "" and errmsg ~= nil) or (meta:get_int("ts_ui") == 0) then
        if (errmsg ~= "" and errmsg ~= nil) then meta:set_int("ts_ui", 0) end
        local is_robot = meta:get_int("robot") == 1
        local tab = meta:get_int("tab")
        if tab < 1 or tab > 5 then tab = 1 end

        local fs = "formspec_version[4]"
            .. "size[15,12]"
            .. "style_type[label,textarea,field;font=mono]"
            .. "style_type[textarea;textcolor=#ffffff]"
            .. "background[0,0;15,12;laptop_ui_bg.png]"
            .. "tabheader[0,0;tab;Code,Terminal,Help,Inventory;" .. tab .. "]"
            .. "image_button_exit[14.5,0;0.425,0.4;jeija_close_window.png;exit;]"

        if tab == 1 then
            --Code tab
            fs = fs .. "label[0.1,10;" .. errmsg .. "]"
                .. "textarea[0.25,0.6;14.5,9.05;code;;" .. code .. "]"
                .. "image_button[3.75,10.25;2.5,1;laptop_ui_run.png;program;]"
                .. "image_button[6.50,10.25;2.5,1;laptop_ui_stop.png;halt;]"
                .. "image_button[9.25,10.25;2.5,1;laptop_ui_gui.png;show_gui;]"
        elseif tab == 2 then
            local term_text = escape(meta:get_string("term_text"))
            --Terminal tab
            fs = fs .. "textarea[0.25,0.6;14.5,9.05;;;" .. term_text .. "]"
                .. "field[0.25,9.85;12.5,1;terminal_input;;]"
                .. "button[12.75,9.85;2,1;terminal_send;Send]"
                .. "button[12.75,10.85;2,1;terminal_clear;Clear]"
                .. "field_close_on_enter[terminal_input;false]"
        elseif tab == 3 then
            fs = fs ..
                "textarea[0.25,0.6;14.5,9.05;;;See https://github.com/TheEt1234/libox_computer/blob/master/DOCS.md]"
        elseif tab == 4 and not is_robot then
            fs = fs ..
                "textarea[0.25,0.6;14.5,9.05;;;This is a laptop, not a robot.]"
        elseif tab == 4 and is_robot then
            fs = fs
                .. "style_type[list;size=0.7,0.7;spacing=0.1,0.1]"
                .. "list[current_name;main;0.65,0.8;17,8;]"
                .. "list[current_player;main;0.65,7.6;17,5;]"
                .. "listring[]"
        end
        meta:set_string("formspec", fs)
        --meta:set_string("errmsg", "")
    end
end

local function on_receive_fields(pos, _, fields, sender)
    local name = sender:get_player_name()


    local meta = minetest.get_meta(pos)
    local ts_ui = meta:get_int("ts_ui")
    if ts_ui == 0 then
        if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, { protection_bypass = true }) then
            minetest.record_protection_violation(pos, name)
            return
        end

        if fields.tab then
            meta:set_int("tab", fields.tab)
            ui(meta)
        elseif fields.program then
            -- problem, what happens to the previous sandbox
            -- well it gets deleted we dont make garbage here
            libox.coroutine.active_sandboxes[meta:get_string("ID")] = nil
            meta:set_string("ID", "AAAAAAAAAA")
            meta:set_string("errmsg", "")
            meta:set_int("ts_ui", 0)
            meta:set_string("code", fields.code)
            meta:set_string("data", minetest.serialize({}))

            libox_computer.sandbox.create_sandbox(pos)
            libox_computer.sandbox.run_sandbox(pos)
            ui(meta)
        elseif fields.terminal_clear then
            meta:set_string("term_text", "")
            ui(meta)
        elseif fields.terminal_send then
            libox_computer.sandbox.wake_up_and_run(pos, {
                type = "terminal",
                msg = fields.terminal_input
            })
        elseif fields.halt then
            meta:set_string("errmsg", "")
            libox.coroutine.active_sandboxes[meta:get_string("ID")] = nil
            ui(meta)
        elseif fields.show_gui then
            meta:set_int("ts_ui", 1)
            libox_computer.touchscreen_protocol.update_formspec(meta, minetest.deserialize(meta:get_string("data"), true))
        end
    elseif ts_ui == 1 then
        if fields.hide_gui then
            meta:set_int("ts_ui", 0)
            ui(meta)
        end
        if mesecon.get_heat(pos) < (libox_computer.settings.heat_max - 2) then -- this gives you time to wait or something idk
            libox_computer.touchscreen_protocol.on_gui_receive_fields(pos, _, fields, sender)
        end
    end
end

libox_computer.ui = ui
libox_computer.on_receive_fields = on_receive_fields
