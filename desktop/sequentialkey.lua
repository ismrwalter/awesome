local awful = require("awful")
local hotkeys_popup = require("awful.hotkeys_popup")
local wibox = require("wibox")
local beautiful = require("beautiful")

local module = {}

create_key_help = function(keys, options)
    local description = options.description or ""
    local key_tips = wibox.widget {
        homogeneous   = true,
        spacing       = 5,
        min_cols_size = 300,
        min_rows_size = 10,
        forced_num_cols = 2,
        layout        = wibox.layout.grid,
    }

    for i, item in ipairs(keys) do
        local mod, key, callback, other = item[1], item[2], item[3], item[4]

        local mod_text = table.concat(mod, "+")
        if mod_text ~= "" then
            mod_text = mod_text .. "+"
        end

        key_tips:add(
            wibox.widget {
                markup = "<b>" .. mod_text .. key:lower() .. "</b>\t<i>" .. other.description .. "</i>",
                align = "left",
                valign = "center",
                widget = wibox.widget.textbox
            }
        )
    end
    local wrapper_widget =
    {
        key_tips,
        margins = 40,
        widget = wibox.container.margin
    }
    local popup_indicator =
        awful.popup {
        widget = wrapper_widget,
        ontop = true,
        border_color = "#00ff00",
        border_width = 5,
        border_width = 0,
        placement = function(d, args)
            return awful.placement.centered(
                d,
                {
                    parent = options.parent
                }
            )
        end,
        bg = beautiful.hotkeys_bg,
        visible = false
    }
    return popup_indicator
end

create_key_bindings = function(keys, options)
    local popup_indicator = create_key_help(keys, options)
    local grabber =
        awful.keygrabber {
        mask_modkeys = false,
        stop_key = "Escape",
        autostart = true,
        -- timeout = 1,
        start_callback = function(self)
            popup_indicator.visible = true
        end,
        stop_callback = function(self, stop_key, stop_mods, sequence)
            popup_indicator.visible = false
        end
    }
    for i, item in ipairs(keys) do
        local mod, key, body, other = item[1], item[2], item[3], item[4]

        if type(body) == "table" then
            grabber:add_keybinding(
                mod,
                key,
                function()
                    grabber:stop()
                    create_key_bindings(body, options)
                end,
                other
            )
        elseif type(body) == "function" then
            grabber:add_keybinding(
                mod,
                key,
                function()
                    if not (other.hold == true) then
                        grabber:stop()
                    end
                    body(options.args)
                end,
                other
            )
        end
    end
    return grabber
end

module.show = function(keys, options)
    create_key_bindings(keys, options)
end

return setmetatable(
    module,
    {
        __call = function(_, ...)
            return module.show(...)
        end
    }
)
