hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60.00",
    position = "0x0",
    scale    = 1,
    vrr      = 0,
})

-- any other output (projector, dock)
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})
