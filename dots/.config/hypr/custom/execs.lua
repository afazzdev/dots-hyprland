-- Custom autostart (loaded after hyprland/execs.lua via hyprland.lua)
hl.on("hyprland.start", function()
    -- hyprgrass via hyprpm (replaces manual ~/.config/hypr/plugins build).
    -- Kept manual .so at ~/.config/hypr/plugins/hyprgrass/libhyprgrass.so as fallback only.
    hl.exec_cmd("hyprpm reload -n")
end)
