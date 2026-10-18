# Universal aliases

# Colorize output
alias ls="ls -hN --color=auto --group-directories-first"
alias grep="grep --color=auto"
alias diff="diff --color=auto"
alias ip="ip -color=auto"

# Safe file operations
alias cp="cp -iv"
alias mv="mv -iv"
alias rm="rm -vI"
alias rsync="rsync -vrPlu"
alias l="ls -lah --color=always --group-directories-first"

# Abbreviations for common tasks
alias g="git"
alias v='$EDITOR'
alias e='$EDITOR'
alias vim='$EDITOR'
alias mkd="mkdir -pv"
alias yt="yt-dlp --embed-metadata -i"
alias pubip="dig +short myip.opendns.com @resolver1.opendns.com"
alias ffmpeg="ffmpeg -hide_banner"
alias ccat="highlight --out-format=ansi"

# Git shortcuts
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

# FZF with bat preview
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias eff='$EDITOR $(ff)'

# Auto-sudo system commands (the loop builds each alias, so the name is meant to expand here)
for command in mount umount pacman su shutdown poweroff reboot; do
    # shellcheck disable=SC2139
    alias $command="sudo $command"
done; unset command

# Application wrappers
alias lf="lfcd"
alias media-env="source ~/.local/share/venvs/media/bin/activate"

# The configuration repository (~/dox/repos/infra)
alias infra='git -C "$HOME/dox/repos/infra"'
alias cfg='infra'


# GCC Compilation flags
alias gpp="g++ -Wall -Weffc++ -Wextra -Wconversion -Wsign-conversion -Werror -std=c++20"
