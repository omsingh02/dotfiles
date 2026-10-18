-- Border colours from the theme engine's file. It is hyprlang (`$name = rgb(...)`, hyprlock reads it too) and Lua cannot
-- `source` it, so it is parsed here on every load and reload. Live changes after a wallpaper change are pushed by
-- theme-daemon with `hyprctl eval`; nothing polls. Without the file (a cold boot before the first wallpaper) the fallbacks apply.

local M = {}

M.path = (os.getenv("HOME") or "") .. "/.cache/theme/colors-hyprland.conf"

M.fallback = {
    background = "rgb(000000)",
    color2     = "rgb(111111)",
    color4     = "rgb(222222)",
}

-- primary to secondary is what theme-daemon pushes after every wallpaper change, so a reload keeps the look
M.active   = { "primary", "secondary" }
M.active_fallback = { "color2", "color4" }
M.inactive = "background"
M.angle    = 45

local COLOR_PATTERNS = {
    "^rgba?%(%x+%)$",
    "^rgba?%([%d%.,]+%)$",
    "^0x%x+$",
}

local function is_color(v)
    for _, p in ipairs(COLOR_PATTERNS) do
        if v:match(p) then return true end
    end
    return false
end

function M.read()
    local f = io.open(M.path, "r")
    if not f then return nil end
    local text = f:read("a")
    f:close()
    return text
end

function M.parse(text)
    local vars = {}
    for line in (text or ""):gmatch("[^\r\n]+") do
        local name, value = line:match("^%s*%$([%w_]+)%s*=%s*(.-)%s*$")
        if name then
            value = value:gsub("%s+#.*$", "")
            if is_color(value) then vars[name] = value end
        end
    end
    return vars
end

function M.load(text)
    local c = {}
    for k, v in pairs(M.fallback) do c[k] = v end
    for k, v in pairs(M.parse(text)) do c[k] = v end
    return c
end

function M.borders(c)
    c = c or M.colors
    local a = c[M.active[1]] or c[M.active_fallback[1]]
    local b = c[M.active[2]] or c[M.active_fallback[2]]
    return {
        active_border   = { colors = { a, b }, angle = M.angle },
        inactive_border = c[M.inactive] or M.fallback.background,
    }
end

function M.apply(c)
    hl.config({ general = { col = M.borders(c) } })
end

M.colors = M.load(M.read())

theme = M
return M
