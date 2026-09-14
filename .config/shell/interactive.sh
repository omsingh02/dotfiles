# Cross-shell interactive tools (FZF, Zoxide, Pywal)

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

# Pywal colors
if [ -z "$TMUX" ] && [ -f ~/.cache/theme/sequences ]; then
    (cat ~/.cache/theme/sequences &)
fi
[ -f ~/.cache/theme/colors.sh ] && source ~/.cache/theme/colors.sh

# Greeting
pokemon-colorscripts -r

true
