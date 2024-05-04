local escape = minetest.formspec_escape

local function ui(meta)
    local code = escape(meta:get_string("code"))
    local errmsg = escape(meta:get_string("errmsg"))
    if (errmsg ~= "" and errmsg ~= nil) or (meta:get_int("ts_ui") == 0) then
        local tab = meta:get_int("tab")
        if tab < 1 or tab > 4 then tab = 1 end

        local fs = "formspec_version[4]"
            .. "size[15,12]"
            .. "style_type[label,textarea,field;font=mono]"
            .. "style_type[textarea;textcolor=#ffffff]"
            .. "background[0,0;15,12;laptop_ui_bg.png]"
            .. "tabheader[0,0;tab;Code,Terminal,Help;" .. tab .. "]"
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
            --Help tab
            --fs = fs .. mooncontroller.lc_docs.generate_help_formspec(meta:get_int("help_selidx"))
        end
        meta:set_string("formspec", fs)
    end
end

local function on_receive_fields(pos, _, fields, sender)
    local name = sender:get_player_name()
    if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, { protection_bypass = true }) then
        minetest.record_protection_violation(pos, name)
        return
    end

    local meta = minetest.get_meta(pos)

    if fields.tab then
        meta:set_int("tab", fields.tab)
        ui(meta)
    elseif fields.program then
        meta:set_int("ts_ui", 0)
        meta:set_string("code", fields.code)
        -- problem, what happens to the previous sandbox
        -- well it gets deleted we dont make garbage here
        libox.coroutine.active_sandboxes[meta:get_string("ID")] = nil

        libox_computer.sandbox.create_sandbox(pos)
        libox_computer.sandbox.run_sandbox(pos)
    elseif fields.terminal_clear then
        meta:set_string("term_text", "")
        ui(meta)
    elseif fields.terminal_send then
        libox_computer.sandbox.wake_up_and_run(pos, {
            type = "terminal_send",
            msg = fields.terminal_input
        })
    elseif fields.stop then
        libox.coroutine.active_sandboxes[meta:get_string("ID")] = nil
    elseif fields.show_gui then
        meta:set_int("ts_ui", 1)
        libox_computer.touchscreen_protocol.update_formspec(meta, minetest.deserialize(meta:get_string("data"), true))
    elseif meta:get_int("ts_ui") == 1 then
        libox_computer.touchscreen_protocol.on_gui_receive_fields(pos, _, fields, sender)
    end
end

libox_computer.ui = ui
libox_computer.on_receive_fields = on_receive_fields
