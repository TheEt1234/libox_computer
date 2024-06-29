local settings = libox_computer.settings

function libox_computer.digiline_wrap(f)
    setfenv(f, {}) -- make the function have to import its environment
    return f
end

function libox_computer.raw_print(meta, text)
    local old_text = meta:get_string("term_text")
    meta:set_string("term_text", string.sub(old_text .. text, -100000, -1))
end

function libox_computer.report_error(meta, text, preceeding_text)
    preceeding_text = preceeding_text or "[ERROR] "
    text = libox.shorten_path(tostring(text) or "")
    libox_computer.raw_print(meta, preceeding_text .. text .. "\n")
    meta:set_string("errmsg", text)
    libox_computer.ui(meta)
end

function libox_computer.get_digiline_send(pos)
    return function(channel, msg)
        if type(channel) ~= "string" and type(channel) ~= "number" and type(channel) ~= "boolean" then
            return "Channel must be string, number or boolean."
        end
        if #channel > settings.chan_maxlen then
            return "Channel string too long"
        end
        local msg_cost
        msg, msg_cost = libox.digiline_sanitize(msg, settings.allow_functions_in_digiline_messages,
            libox_computer.wrap)
        if msg == nil or msg_cost > settings.maxlen then
            return "Too complex or contained invalid data"
        end
        mesecon.queue:add_action(pos, "lb_digiline_relay", { channel, msg })
    end
end

function libox_computer.get_print(meta) -- from mooncontroller
    return function(param, nolf)
        if param == nil then param = "" end
        local delim = "\n"
        if nolf then delim = "" end
        if type(param) == "string" then
            libox_computer.raw_print(meta, param .. delim)
        else
            libox_computer.raw_print(meta, dump(param) .. delim)
        end
    end
end

function libox_computer.get_clearterm(meta)
    return function() meta:set_string("term_text", "") end
end
