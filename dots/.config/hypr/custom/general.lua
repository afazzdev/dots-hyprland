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

-- hyprgrass via hyprpm (was manual build, migrated).
hl.config({
    plugin = {
        hyprgrass = {
            sensitivity = 2.5,
            long_press_delay = 500,
            edge_margin = 10,
            resize_on_border_long_press = true,
        },
    },
    gestures = {
        workspace_swipe_touch = true,
        workspace_swipe_cancel_ratio = 0.15,
    },
})

-- Touchscreen gestures (guarded: only after hyprpm loads hyprgrass).
-- Mirrors dotfile core: SUPER+Q close, SUPER+F fullscreen, SUPER+ALT+Space float,
-- SUPER+S special, SUPER+Tab overview, SUPER+K osk. No swipe-to-close: every
-- close path is deliberate (4-finger longpress).
if hl.plugin and hl.plugin.hyprgrass then
    -- 3-finger horizontal swipe: workspace switch (1:1)
    hl.plugin.hyprgrass.gesture({
        pattern = { kind = "swipe", fingers = 3, direction = "horizontal" },
        action = "workspace",
    })
    -- Edge swipe up->down: scratchpad (SUPER+S)
    hl.plugin.hyprgrass.gesture({
        pattern = { kind = "edge", origin = "up", direction = "down" },
        action = "special",
    })
    -- 2-finger horizontal swipe: scroll the tape (only on scrolling-layout
    -- workspaces, e.g. workspace 10 — see custom/rules.lua)
    hl.plugin.hyprgrass.gesture({
        pattern = { kind = "swipe", fingers = 2, direction = "horizontal" },
        action = "scroll_move",
    })
    -- 3-finger swipe down: search (must be searchToggle, NOT searchToggleRelease:
    -- Release only fires on physical key release, which touch gestures lack)
    hl.plugin.hyprgrass.bind({
        pattern = { kind = "swipe", fingers = 3, direction = "down" },
        action = hl.dsp.global("quickshell:searchToggle"),
    })
    -- 3-finger tap: float toggle (SUPER+ALT+Space)
    hl.plugin.hyprgrass.bind({
        pattern = { kind = "tap", fingers = 3 },
        action = hl.dsp.window.float(),
    })
    -- 3-finger longpress: window drag via mouse bind
    hl.plugin.hyprgrass.bind({
        pattern = { kind = "longpress", fingers = 3 },
        action = hl.dsp.window.drag(),
        mouse = true,
    })
    -- 4-finger tap: fullscreen toggle (SUPER+F)
    hl.plugin.hyprgrass.bind({
        pattern = { kind = "tap", fingers = 4 },
        action = hl.dsp.window.fullscreen(),
    })
    -- 4-finger swipe left/right: overview (SUPER+Tab)
    -- NOTE: hyprgrass bind requires a single direction (left/right/up/down),
    -- "horizontal" is gesture-only, so bind both sides.
    hl.plugin.hyprgrass.bind({
        pattern = { kind = "swipe", fingers = 4, direction = "left" },
        action = hl.dsp.global("quickshell:overviewWorkspacesToggle"),
    })
    hl.plugin.hyprgrass.bind({
        pattern = { kind = "swipe", fingers = 4, direction = "right" },
        action = hl.dsp.global("quickshell:overviewWorkspacesToggle"),
    })
    -- 4-finger longpress: close window (SUPER+Q) — deliberate only
    hl.plugin.hyprgrass.bind({
        pattern = { kind = "longpress", fingers = 4 },
        action = hl.dsp.window.close(),
    })
    -- 5-finger tap: on-screen keyboard (SUPER+K, built into quickshell)
    hl.plugin.hyprgrass.bind({
        pattern = { kind = "tap", fingers = 5 },
        action = hl.dsp.global("quickshell:oskToggle"),
    })
    -- 5-finger tap ON LOCKSCREEN: toggle wvkbd (quickshell OSK hides itself
    -- when locked, so a standalone keyboard is needed to type the password).
    -- hyprgrass only fires binds whose `locked` flag matches the session state,
    -- hence this deliberate duplicate. Requires: yay -S wvkbd
    hl.plugin.hyprgrass.bind({
        pattern = { kind = "tap", fingers = 5 },
        action = hl.dsp.exec_cmd("sh -c 'pkill -f wvkbd || (wvkbd-mobintl || wvkbd)'"),
        locked = true,
    })
end
