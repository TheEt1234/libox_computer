function libox_computer.wrap(f)
    setfenv(f, {}) -- make the function have to import its environment
    return f
end

function libox_computer.raw_print(meta, text)
    local old_text = meta:get_string("term_text")
    meta:set_string("term_text", string.sub(old_text .. text, -100000, -1))
    libox_computer.ui(meta)
end

function libox_computer.report_error(meta, text, preceeding_text)
    local preceeding_text = preceeding_text or "[ERROR] "
    libox_computer.raw_print(meta, preceeding_text .. text .. "\n")
    meta:set_string("errmsg", text)
    libox_computer.ui(meta)
end

function libox_computer.get_digiline_send(pos)
    return function(channel, msg)
        if type(channel) == "string" then
            if #channel > settings.chan_maxlen then
                return "Channel string too long"
            elseif (type(channel) ~= "string" and type(channel) ~= "number" and type(channel) ~= "boolean") then
                return "Channel must be string, number or boolean."
            end
            local msg, msg_cost = libox.digiline_sanitize(msg, settings.allow_functions_in_digiline_messages,
                libox_computer.wrap)
            if msg == nil or msg_cost > settings.maxlen then
                return "Too complex or contained invalid data"
            end
        end
        mesecon.queue:add_action(pos, "lb_digiline_relay", { channel, msg })
    end
end

function libox_computer.get_print(meta) -- mooncontroller like
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

function libox_computer.safe_coroutine_resume(...)
    --[[
    THIS USES RAW PCALL..... AAND CALLS STUFF FROM THE USER
    so we need to be very careful
    and by that i mean we can't use sandbox_lib_f because that will allow the user to (""):rep(math.huge)
]]
    local retvalue = {
        coroutine.resume(co, ...)
    }
    if not debug.gethook() then
        error("Code timed out! (from coroutine.resume)", 2)
    end
    return retvalue
end
