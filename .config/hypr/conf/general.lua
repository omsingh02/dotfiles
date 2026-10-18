local T = theme or require("conf/theme")

hl.config({
    general = {
        gaps_in     = 0,
        gaps_out    = 0,
        border_size = 2,

        col = T.borders(),   -- the palette theme-daemon pushes live, so a reload keeps the look

        layout           = "master",
        resize_on_border = false,
        allow_tearing    = true,   -- the immediate rules for games need it
    },

    decoration = {
        rounding         = 0,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = false,
        },
        blur = {
            enabled           = true,   -- power-daemon switches it at runtime; a reload resets it to this
            passes            = 4,
            size              = 10,
            new_optimizations = true,
            xray              = true,
            noise             = 0.03,
            contrast          = 0.9,
            brightness        = 0.82,

            vibrancy          = 0.1696,
            vibrancy_darkness = 0.0,
        },
    },

    animations = {
        enabled = true,
    },

    master = {
        new_status           = "master",
        mfact                = 0.55,
        special_scale_factor = 0.8,
    },

    misc = {
        disable_autoreload         = true,   -- reload only on purpose (Super+Ctrl+Shift+R): a half-edited file must not reach the session
        force_default_wallpaper    = -1,
        disable_hyprland_logo      = true,
        disable_splash_rendering   = true,
        enable_swallow             = true,
        swallow_regex              = "^(foot)$",
        enable_anr_dialog          = true,
        anr_missed_pings           = 10,
        allow_session_lock_restore = true,
        middle_click_paste         = false,
        mouse_move_enables_dpms    = true,
        key_press_enables_dpms     = true,
    },

    cursor = {
        inactive_timeout  = 3,
        hide_on_key_press = true,
    },

    render = {
        direct_scanout = 0,
    },

    binds = {
        workspace_back_and_forth         = true,
        allow_workspace_cycles           = true,
        hide_special_on_workspace_change = true,
    },

    xwayland = {
        force_zero_scaling = true,
    },

    ecosystem = {
        no_update_news = true,
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 },   { 0.32, 1 } } })
hl.curve("linear",       { type = "bezier", points = { { 0, 0 },      { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 },  { 0.75, 1.0 } } })
hl.curve("quick",        { type = "bezier", points = { { 0.15, 0 },   { 0.1, 1 } } })

hl.animation({ leaf = "windows",    enabled = true, speed = 4,   bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4,   bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "linear",       style = "popin 87%" })

hl.animation({ leaf = "fadeIn",  enabled = true, speed = 1.7, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.5, bezier = "almostLinear" })
hl.animation({ leaf = "fade",    enabled = true, speed = 3,   bezier = "quick" })

hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "easeOutQuint" })

hl.animation({ leaf = "layers",        enabled = true, speed = 3.8, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,   bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5, bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.8, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.4, bezier = "almostLinear" })

hl.animation({ leaf = "workspaces", enabled = false })

hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidevert" })
