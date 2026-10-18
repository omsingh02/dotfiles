local P = programs or require("conf/programs")
local exec = hl.dsp.exec_cmd

local mainMod = "SUPER"
local altMod  = "ALT"

hl.bind(mainMod .. " + Return", exec(P.terminal), { description = "Terminal" })
hl.bind(mainMod .. " + W", exec(P.browser), { description = "Browser" })
hl.bind(mainMod .. " + E", exec("footclient -e lf"), { description = "File manager (lf)" })
hl.bind(mainMod .. " + N", exec("footclient -e newsboat"), { description = "News reader (newsboat)" })
hl.bind(mainMod .. " + grave", exec("~/.local/bin/emoji-picker"), { description = "Emoji picker" })

hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close window" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit(), { description = "Exit Hyprland" })
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }), { description = "Move window left" })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }), { description = "Move window right" })
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }), { description = "Move window up" })
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }), { description = "Move window down" })
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }), { description = "Focus left" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { description = "Focus right" })
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }), { description = "Focus up" })
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }), { description = "Focus down" })
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }), { description = "Floating (toggle)" })
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), { description = "Maximize (toggle)" })
hl.bind(mainMod .. " + BackSpace", exec("~/.local/bin/sysact"), { description = "Power menu" })
hl.bind(mainMod .. " + L", exec("loginctl lock-session"), { description = "Lock screen" })
hl.bind(mainMod .. " + Space", hl.dsp.layout("swapwithmaster"), { description = "Swap with master" })
hl.bind(mainMod .. " + S", hl.dsp.window.pin({ action = "toggle" }), { description = "Pin window (toggle)" })
hl.bind(mainMod .. " + CTRL + SHIFT + R", exec("hyprctl reload"), { description = "Reload the Hyprland config" })
hl.bind(mainMod .. " + B", exec("systemctl --user --quiet is-active waybar.service && systemctl --user stop waybar.service || systemctl --user start waybar.service"), { description = "Bar on or off" })
hl.bind(mainMod .. " + D", exec("~/.local/bin/syspanel show"), { description = "Notification panel" })
hl.bind(mainMod .. " + SHIFT + D", exec("~/.local/bin/syspanel clear"), { description = "Clear notifications" })
hl.bind(mainMod .. " + CTRL + D", exec("~/.local/bin/syspanel dnd-toggle"), { description = "Do not disturb (toggle)" })

hl.bind(altMod .. " + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "Cycle windows" })

hl.bind(mainMod .. " + T", function() hl.config({ general = { layout = "master" } }) end, { description = "Master layout" })
hl.bind(mainMod .. " + Y", function() hl.config({ general = { layout = "dwindle" } }) end, { description = "Dwindle layout" })

hl.bind(mainMod .. " + J", hl.dsp.layout("cyclenext"), { description = "Next window in layout" })
hl.bind(mainMod .. " + K", hl.dsp.layout("cycleprev"), { description = "Previous window in layout" })
hl.bind(mainMod .. " + I", hl.dsp.layout("addmaster"), { description = "Add a master" })
hl.bind(mainMod .. " + O", hl.dsp.layout("removemaster"), { description = "Remove a master" })
hl.bind(mainMod .. " + CTRL + M", hl.dsp.layout("focusmaster"), { description = "Focus master" })
hl.bind(mainMod .. " + Tab", hl.dsp.layout("orientationcycle left top"), { description = "Cycle layout orientation" })

hl.bind(mainMod .. " + CTRL + R", hl.dsp.submap("resize"), { description = "Resize mode (Esc or Return to leave)" })
hl.define_submap("resize", function()
    local function resize(x, y)
        return hl.dsp.window.resize({ x = x, y = y, relative = true })
    end
    hl.bind("H", resize(-40, 0), { repeating = true, description = "Resize: narrower" })
    hl.bind("L", resize(40, 0), { repeating = true, description = "Resize: wider" })
    hl.bind("K", resize(0, -40), { repeating = true, description = "Resize: shorter" })
    hl.bind("J", resize(0, 40), { repeating = true, description = "Resize: taller" })
    hl.bind("left", resize(-40, 0), { repeating = true, description = "Resize: narrower" })
    hl.bind("right", resize(40, 0), { repeating = true, description = "Resize: wider" })
    hl.bind("up", resize(0, -40), { repeating = true, description = "Resize: shorter" })
    hl.bind("down", resize(0, 40), { repeating = true, description = "Resize: taller" })
    hl.bind("Escape", hl.dsp.submap("reset"), { description = "Leave resize mode" })
    hl.bind("Return", hl.dsp.submap("reset"), { description = "Leave resize mode" })
end)

hl.bind(mainMod .. " + A", exec("blueman-manager"), { description = "Bluetooth manager" })

hl.bind(mainMod .. " + SHIFT + Return", exec([[~/.local/bin/smart-scratchpad spterm spterm "foot --app-id spterm"]]), { description = "Terminal scratchpad" })
hl.bind(mainMod .. " + C", exec([[~/.local/bin/smart-scratchpad spcalc spcalc "foot --app-id spcalc -e bc -lq"]]), { description = "Calculator scratchpad" })
hl.bind(altMod .. " + M", exec([[~/.local/bin/smart-scratchpad spncmpcpp spncmp "foot --app-id spncmpcpp -e ncmpcpp"]]), { description = "Music player scratchpad (ncmpcpp)" })
hl.bind(mainMod .. " + V", exec([[~/.local/bin/smart-scratchpad spmixer spmixer "foot --app-id spmixer -e pulsemixer"]]), { description = "Volume mixer scratchpad" })
hl.bind(altMod .. " + S", exec([[~/.local/bin/toggle-webapp spspotify "brave-origin --app='https://open.spotify.com/'"]]), { description = "Spotify (web app)" })
hl.bind(altMod .. " + W", exec([[~/.local/bin/toggle-webapp spwhatsapp "brave-origin --profile-directory='Default' --app='https://web.whatsapp.com/'"]]), { description = "WhatsApp (web app)" })
hl.bind(altMod .. " + SHIFT + M", exec([[~/.local/bin/toggle-webapp spmsite "brave-origin --app='https://m.omsingh.me/'"]]), { description = "m.omsingh.me (web app)" })
hl.bind(altMod .. " + R", exec("~/.local/bin/wa-reel-menu"), { description = "WhatsApp reel menu" })

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:spterm", follow = false }), { description = "Send window to the terminal scratchpad" })

-- tapping Super opens the launcher on release; a second tap closes it
hl.bind(mainMod .. " + SUPER_L", exec("pkill fuzzel || " .. P.menu), { release = true, description = "App launcher (tap Super)" })
hl.bind(mainMod .. " + CTRL + W", exec("~/.local/bin/theme random"), { description = "Random wallpaper" })
hl.bind(mainMod .. " + F12", exec("~/.local/bin/hark-waybar toggle"), { description = "Pause or resume song recognition (hark)" })
hl.bind(mainMod .. " + SHIFT + F12", exec("~/.local/bin/hark-waybar now"), { description = "Show the song hark recognised" })
hl.bind(mainMod .. " + SHIFT + L", exec("~/.local/bin/wall-lyrics-toggle"), { description = "Lyrics on the wallpaper (toggle)" })
hl.bind(mainMod .. " + ALT + C", exec("cliphist list | fuzzel -d | cliphist delete"), { description = "Clipboard: delete an entry" })
hl.bind(altMod .. " + C", exec("cliphist list | fuzzel -d | cliphist decode | wl-copy"), { description = "Clipboard history" })
hl.bind(mainMod .. " + U", exec("~/.local/bin/link-handler"), { description = "Open a link (link handler)" })

hl.bind("Print", exec("~/.local/bin/screenshot full"), { description = "Screenshot: full screen" })
hl.bind("SHIFT + Print", exec("~/.local/bin/screenshot region"), { description = "Screenshot: region" })
hl.bind(altMod .. " + Print", exec("~/.local/bin/screenshot ocr"), { description = "Screenshot: read text (OCR)" })

hl.bind(mainMod .. " + Print", exec("~/.local/bin/screenrecord toggle"), { description = "Screen recording (toggle)" })
hl.bind(mainMod .. " + SHIFT + Print", exec("~/.local/bin/screenrecord region"), { description = "Screen recording: region" })
hl.bind(mainMod .. " + Delete", exec("~/.local/bin/screenrecord stop"), { description = "Screen recording: stop" })
hl.bind(mainMod .. " + Pause", exec("~/.local/bin/screenrecord pause"), { description = "Screen recording: pause" })

for i = 1, 10 do
    local key = i % 10   -- the 0 key is workspace 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = true }), { description = "Move window to workspace " .. i })
end

hl.bind(mainMod .. " + G", hl.dsp.focus({ workspace = "m-1" }), { description = "Previous workspace" })
hl.bind(mainMod .. " + semicolon", hl.dsp.focus({ workspace = "m+1" }), { description = "Next workspace" })
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.window.move({ workspace = "m-1", follow = true }), { description = "Move window to the previous workspace" })
hl.bind(mainMod .. " + SHIFT + semicolon", hl.dsp.window.move({ workspace = "m+1", follow = true }), { description = "Move window to the next workspace" })

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag window (hold)" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window (hold)" })

hl.bind(mainMod .. " + minus", exec("~/.local/bin/sysnotify volume_down"), { repeating = true, description = "Volume down" })
hl.bind(mainMod .. " + equal", exec("~/.local/bin/sysnotify volume_up"), { repeating = true, description = "Volume up" })
hl.bind(mainMod .. " + SHIFT + minus", exec("~/.local/bin/sysnotify volume_down_big"), { repeating = true, description = "Volume down (big step)" })
hl.bind(mainMod .. " + SHIFT + equal", exec("~/.local/bin/sysnotify volume_up_big"), { repeating = true, description = "Volume up (big step)" })
hl.bind(mainMod .. " + SHIFT + M", exec("~/.local/bin/sysnotify volume_mute"), { description = "Mute (toggle)" })

hl.bind("XF86AudioRaiseVolume", exec("~/.local/bin/sysnotify volume_up"), { locked = true, repeating = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume", exec("~/.local/bin/sysnotify volume_down"), { locked = true, repeating = true, description = "Volume down" })
hl.bind("XF86AudioMute", exec("~/.local/bin/sysnotify volume_mute"), { locked = true, repeating = true, description = "Mute (toggle)" })
hl.bind("XF86AudioMicMute", exec("~/.local/bin/sysnotify mic_mute"), { locked = true, repeating = true, description = "Microphone mute (toggle)" })

hl.bind("XF86MonBrightnessUp", exec("~/.local/bin/sysnotify brightness_up"), { locked = true, repeating = true, description = "Brightness up" })
hl.bind("XF86MonBrightnessDown", exec("~/.local/bin/sysnotify brightness_down"), { locked = true, repeating = true, description = "Brightness down" })

hl.bind("XF86AudioNext", exec("~/.local/bin/media next"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPause", exec("~/.local/bin/media toggle"), { locked = true, description = "Play or pause" })
hl.bind("XF86AudioPlay", exec("~/.local/bin/media toggle"), { locked = true, description = "Play or pause" })
hl.bind("XF86AudioPrev", exec("~/.local/bin/media prev"), { locked = true, description = "Previous track" })
hl.bind(mainMod .. " + bracketright", exec("~/.local/bin/media seek +10"), { locked = true, description = "Seek forward 10 s" })
hl.bind(mainMod .. " + bracketleft", exec("~/.local/bin/media seek -10"), { locked = true, description = "Seek back 10 s" })
hl.bind(mainMod .. " + SHIFT + bracketright", exec("~/.local/bin/media seek +60"), { locked = true, description = "Seek forward 60 s" })
hl.bind(mainMod .. " + SHIFT + bracketleft", exec("~/.local/bin/media seek -60"), { locked = true, description = "Seek back 60 s" })
hl.bind(mainMod .. " + R", exec("~/.local/bin/media repeat"), { locked = true, description = "Repeat mode (media)" })

-- this laptop has no media keys, hence these letter binds
hl.bind(mainMod .. " + P", exec("~/.local/bin/media toggle"), { description = "Play or pause" })
hl.bind(mainMod .. " + period", exec("~/.local/bin/media next"), { description = "Next track" })
hl.bind(mainMod .. " + comma", exec("~/.local/bin/media prev"), { description = "Previous track" })
hl.bind(mainMod .. " + SHIFT + P", exec("~/.local/bin/media stop"), { description = "Stop playback" })
hl.bind(mainMod .. " + SHIFT + comma", exec("~/.local/bin/media restart"), { description = "Restart track" })

hl.bind(mainMod .. " + SHIFT + Escape", exec("~/.local/bin/prockill"), { description = "Process killer" })
hl.bind(mainMod .. " + slash", exec("~/.local/bin/keybinds-help"), { description = "This keybind list" })

-- screen off and on only (locking is hypridle's job); Hyprland's docs advise against firing dpms straight from a bind,
-- so it runs from a one-shot timer
local function dpms_deferred(action)
    return function()
        hl.timer(function()
            hl.dispatch(hl.dsp.dpms({ action = action }))
        end, { timeout = 500, type = "oneshot" })
    end
end
hl.bind("switch:on:Lid Switch", dpms_deferred("disable"), { locked = true, description = "Lid closed: screen off" })
hl.bind("switch:off:Lid Switch", dpms_deferred("enable"), { locked = true, description = "Lid opened: screen on" })
