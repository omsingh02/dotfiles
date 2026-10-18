hl.config({
    input = {
        kb_layout          = "us",
        kb_options         = "caps:escape",
        follow_mouse       = 1,
        sensitivity        = 0.2,
        repeat_delay       = 250,
        repeat_rate        = 50,
        numlock_by_default = true,
        accel_profile      = "flat",

        touchpad = {
            natural_scroll       = true,
            tap_to_click         = true,
            drag_lock            = 0,
            disable_while_typing = true,
            clickfinger_behavior = true,
        },
    },

    gestures = {
        workspace_swipe_distance     = 250,
        workspace_swipe_cancel_ratio = 0.3,
        workspace_swipe_create_new   = false,
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})
