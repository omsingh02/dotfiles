-- A global, because Hyprland's require() does not cache: modules share this table instead of loading the file again.
programs = {
    terminal    = "foot",
    fileManager = "thunar",
    menu        = "fuzzel",
    browser     = "brave-origin",
}

return programs
