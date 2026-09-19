-- Custom General Settings & Overrides (Lua)
--
-- API: hl.config({ section = { key = value } })
--
-- Examples:
-- hl.config({ general = { gaps_in = 6, gaps_out = 12 } })
-- hl.config({ decoration = { rounding = 12 } })

-- AccuScene HDMI display on the RX 6600: with VRR on (and the cursor on its
-- own hardware plane) page flips never complete — "Cannot commit when a
-- page-flip is awaiting" — and the screen stays black, TTY switching too.
hl.config({
    misc   = { vrr = 0 },
    cursor = { no_hardware_cursors = true },
})

-- US keyboard only. Panacea ships "us,ru" with Alt+Shift switching, which
-- flips to Russian on an accidental Alt+Shift.
hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_options = "",
        touchdevice = {
            enabled = true,
            output = "HDMI-A-1",
        },
    },
})

-- Touch gestures live in custom/hyprgrass.lua (same guarded-require pattern
-- as hyprland.lua: missing file = silently skipped, never an error).
if is_file_exists(HOME .. "/.config/hypr/custom/hyprgrass.lua") then
    require("custom.hyprgrass")
end
