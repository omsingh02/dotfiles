# Cross-shell interactive tools (pager colours, FZF, Zoxide, the terminal's colours, the greeting)

# Pager: coloured man pages, previews through highlight. (The escape bytes were missing in the old env.sh, so the
# colours never worked; \033 is the fix, 2026-10-07.)
export LESS="R"
export LESS_TERMCAP_mb=$'\033[1;31m'
export LESS_TERMCAP_md=$'\033[1;36m'
export LESS_TERMCAP_me=$'\033[0m'
export LESS_TERMCAP_so=$'\033[01;44;33m'
export LESS_TERMCAP_se=$'\033[0m'
export LESS_TERMCAP_us=$'\033[1;32m'
export LESS_TERMCAP_ue=$'\033[0m'
export LESSOPEN="| /usr/bin/highlight -O ansi %s 2>/dev/null"

# FZF
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'

if [ -n "$ZSH_VERSION" ]; then
    [ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh
    [ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
elif [ -n "$BASH_VERSION" ]; then
    [ -f /usr/share/fzf/completion.bash ] && source /usr/share/fzf/completion.bash
    [ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash
fi

# Zoxide
if [ -n "$ZSH_VERSION" ]; then
    command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
elif [ -n "$BASH_VERSION" ]; then
    command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"
fi

# The terminal takes the colours of the current wallpaper (theme-daemon writes them; it also sends them to open terminals)
if [ -z "$TMUX" ] && [ -f ~/.cache/theme/sequences ]; then
    (cat ~/.cache/theme/sequences &)
fi

# Greeting — same sprites as `pokemon-colorscripts -r`, printed directly instead of
# starting Python (~2 ms vs ~170 ms). Pool includes alternate forms; 1/128 shiny like upstream.
_pokemon_greet() {
    local d=/opt/pokemon-colorscripts/colorscripts/small
    [ -d "$d/regular" ] || return 0
    set -- "$d"/regular/*
    shift $(( RANDOM % $# ))
    local name="${1##*/}" f="$1"
    if [ $(( RANDOM % 128 )) -eq 0 ] && [ -f "$d/shiny/$name" ]; then
        f="$d/shiny/$name"; name="$name (shiny)"
    fi
    printf '%s\n' "$name"
    cat "$f"
}
_pokemon_greet
unset -f _pokemon_greet

true
