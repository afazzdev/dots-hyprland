-- Custom workspace rules (loaded after hyprland/rules.lua via hyprland.lua)

-- WM scroll trial: scrolling layout only on workspace 10, dwindle everywhere else.
-- Move a window there, then 2-finger horizontal swipe scrolls the tape.
-- Go global with: hl.config({ general = { layout = "scrolling" } }) in custom/general.lua
hl.workspace_rule({ workspace = "10", layout = "scrolling" })
