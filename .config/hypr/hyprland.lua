-- Entry point. Paths are relative to this file, and globals are shared between modules (`programs`, `theme`).
-- Each module loads under pcall: an error inside one is reported by Hyprland and does not stop the others, and a
-- module that is missing altogether is raised only after the rest has loaded.

local modules = {
    "conf/theme",
    "conf/programs",
    "conf/monitors",
    "conf/autostart",
    "conf/general",
    "conf/input",
    "conf/keybinds",
    "conf/windowrules",
}

local failed = {}
for _, mod in ipairs(modules) do
    local ok, err = pcall(require, mod)
    if not ok then
        failed[#failed + 1] = mod .. ": " .. tostring(err)
    end
end

if #failed > 0 then
    error("hyprland.lua: could not load module(s):\n" .. table.concat(failed, "\n"), 0)
end
