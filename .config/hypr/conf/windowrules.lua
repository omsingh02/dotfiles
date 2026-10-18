-- a tiling layout: apps must not maximise themselves
hl.window_rule({
    name  = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name   = "hotspot-qr-float",
    match  = { title = "^Hotspot QR$" },
    float  = true,
    size   = { 400, 400 },
    center = true,
})

hl.window_rule({
    name      = "war-thunder-optimizations",
    match     = { class = "(?i)war.*thunder" },
    immediate = true,
    no_anim   = true,
    opaque    = true,
})

hl.window_rule({
    name      = "cs2-optimizations",
    match     = { class = "^(cs2)$" },
    immediate = true,
    no_anim   = true,
    opaque    = true,
})

hl.layer_rule({
    name         = "waybar-glass",
    match        = { namespace = "waybar" },
    blur         = true,
    xray         = true,   -- the bar blurs through the windows behind it
    ignore_alpha = 0.5,    -- keeps icons and text sharp
})

-- XWayland drag and drop creates an empty floating window that would steal focus
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "idle-inhibit-fullscreen",
    match = { fullscreen = true },
    idle_inhibit = "fullscreen",
})

hl.window_rule({
    name   = "mpv-rules",
    match  = { class = "^(mpv)$" },
    float  = false,
    opaque = true,
})

hl.window_rule({
    name  = "mpv-pip-rules",
    match = { title = "^(mpvfloat)$" },
    float = true,
    pin   = true,
})

hl.window_rule({
    name      = "brave-rules",
    match     = { class = "^(brave-browser|brave-origin)$" },
    float     = false,
    workspace = "2",
})

-- extension windows have the class brave-<32-letter extension id>
hl.window_rule({
    name   = "brave-extensions",
    match  = { class = "^(brave-[a-p]{32}.*|brave-extension-.*)$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name   = "brave-popups",
    match  = {
        class = "^(brave-browser|brave-origin)$",
        title = "(?i).*(extension|bitwarden|1password|popup|chrome-extension).*",
    },
    float  = true,
    center = true,
})

hl.window_rule({
    name   = "localsend-floating",
    match  = { class = [[^(org\.localsend\.localsend_app|localsend)$]] },
    float  = true,
    size   = { 900, 650 },
    center = true,
})

hl.window_rule({
    name      = "foot-rules",
    match     = { class = "^(foot)$" },
    float     = false,
    workspace = "1",
    opacity   = "0.85 0.75",
})

hl.window_rule({
    name    = "spterm-rules",
    match   = { class = "^(spterm)$" },
    float   = true,
    size    = { 1000, 600 },
    center  = true,
    opacity = "0.85 0.75",
})

hl.window_rule({
    name   = "spcalc-rules",
    match  = { class = "^(spcalc)$" },
    float  = true,
    size   = { 500, 400 },
    center = true,
})

hl.window_rule({
    name   = "spncmpcpp-rules",
    match  = { class = "^(spncmpcpp)$" },
    float  = true,
    size   = { 1000, 600 },
    center = true,
})

hl.window_rule({
    name   = "spmixer-rules",
    match  = { class = "^(spmixer)$" },
    float  = true,
    size   = { 800, 500 },
    center = true,
})

hl.window_rule({
    name      = "spspotify-rules",
    match     = { title = "(?i).*Spotify.*" },
    float     = true,
    size      = { 1000, 600 },
    center    = true,
    workspace = "special:spspotify",
})

hl.window_rule({
    name      = "spspotify-class-rules",
    match     = { class = [[^(brave(-origin)?-open\.spotify\.com.*)$]] },
    float     = true,
    size      = { 1000, 600 },
    center    = true,
    workspace = "special:spspotify",
})

hl.window_rule({
    name      = "spmsite-class-rules",
    match     = { class = [[^(brave(-origin)?-m\.omsingh\.me.*)$]] },
    float     = true,
    size      = { 1000, 600 },
    center    = true,
    workspace = "special:spmsite",
})

hl.window_rule({
    name      = "spwhatsapp-rules",
    match     = { class = [[^(brave(-origin)?-web\.whatsapp\.com.*)$]] },
    float     = true,
    size      = { 1000, 600 },
    center    = true,
    workspace = "special:spwhatsapp",
})

hl.window_rule({
    name      = "spwhatsapp-title-rules",
    match     = { title = "(?i).*WhatsApp.*" },
    float     = true,
    size      = { 1000, 600 },
    center    = true,
    workspace = "special:spwhatsapp",
})

hl.window_rule({
    name      = "antigravity-rules",
    match     = { class = "^(antigravity)$" },
    workspace = "3",
})

hl.window_rule({
    name      = "vscode-rules",
    match     = { class = "^(Code|code-url-handler|code)$" },
    workspace = "3",
    opacity   = "0.85 0.75",
})

hl.window_rule({
    name      = "virt-manager-rules",
    match     = { class = "^(virt-manager)$" },
    workspace = "5",
})

hl.window_rule({
    name      = "vm-rules",
    match     = { class = "^(virt-viewer|remote-viewer|qemu.*|Qemu.*|.+-spice)$" },
    workspace = "5",
})

-- relative to the monitor: 0.56 rule expressions have no % operator
hl.window_rule({
    name  = "wa-reel-player",
    match = { class = "^(wa-reel)$" },
    float = true,
    size  = { 420, 750 },
    pin   = true,
    move  = { "monitor_w*0.72", "monitor_h*0.15" },
})

hl.window_rule({
    name  = "wa-reel-player-title",
    match = { title = "^(wa-reel)$" },
    float = true,
    size  = { 420, 750 },
    pin   = true,
    move  = { "monitor_w*0.72", "monitor_h*0.15" },
})

hl.window_rule({
    name    = "wa-reel-digest-rules",
    match   = { class = "^(wa-reel-digest)$" },
    float   = true,
    size    = { 1000, 600 },
    center  = true,
    opacity = "0.85 0.75",
})

hl.window_rule({
    name   = "approve-floating",
    match  = { class = "^(approve)$" },
    float  = true,
    size   = { 900, 550 },
    center = true,
})

-- dimmed surroundings, so a due reminder is not missed
hl.window_rule({
    name       = "reminders-banner",
    match      = { class = "^(reminders)$" },
    float      = true,
    size       = { 1000, 560 },
    center     = true,
    dim_around = true,
})

hl.window_rule({
    name   = "share-picker-floating",
    match  = { class = "^(hyprland-share-picker)$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name   = "zenity-guvi-floating",
    match  = { class = "^(zenity|guvi-quiz)$" },
    float  = true,
    size   = { 850, 520 },
    center = true,
})
