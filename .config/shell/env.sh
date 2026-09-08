# Environment variables, XDG paths, default programs
# Sourced early by bashrc/zshrc — no interactive stuff here

# XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# Default Programs
export EDITOR="nvim"
export VISUAL="nvim"
export BROWSER="brave"
export TERMINAL="foot"

# Application-specific XDG overrides
export NB_DIR="$XDG_DATA_HOME/nb"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export DOTNET_CLI_HOME="$XDG_DATA_HOME/dotnet"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"
export CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv"
export ANDROID_USER_HOME="$XDG_DATA_HOME/android"
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"
export IPYTHONDIR="$XDG_CONFIG_HOME/ipython"
export JUPYTER_CONFIG_DIR="$XDG_CONFIG_HOME/jupyter"

# PATH
export PATH="$HOME/.local/bin:$HOME/.local/bin/wallpaper-scripts:$PATH"
[ -d "$CARGO_HOME/bin" ] && export PATH="$CARGO_HOME/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# pnpm
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Colorized man pages
export LESS="R"
export LESS_TERMCAP_mb="$(printf '%b' '[1;31m')"
export LESS_TERMCAP_md="$(printf '%b' '[1;36m')"
export LESS_TERMCAP_me="$(printf '%b' '[0m')"
export LESS_TERMCAP_so="$(printf '%b' '[01;44;33m')"
export LESS_TERMCAP_se="$(printf '%b' '[0m')"
export LESS_TERMCAP_us="$(printf '%b' '[1;32m')"
export LESS_TERMCAP_ue="$(printf '%b' '[0m')"
export LESSOPEN="| /usr/bin/highlight -O ansi %s 2>/dev/null"

# API keys (kept out of dotfiles)
[ -f "$XDG_CONFIG_HOME/.secrets" ] && source "$XDG_CONFIG_HOME/.secrets"
