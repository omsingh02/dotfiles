-- One command, so WAYLAND_DISPLAY and the rest are in the user manager before the session target starts the daemons.
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE && systemctl --user start hyprland-session.target")
end)

-- Blocking, with a short sleep (the wiki's pattern): the target has to be stopped before the compositor goes away.
hl.on("hyprland.shutdown", function()
    os.execute("systemctl --user stop hyprland-session.target && sleep 0.1")
end)
