# ~/.bash_profile: the login hook (environment, Hyprland on tty1), then the interactive setup
[ -f ~/.config/shell/profile ] && . ~/.config/shell/profile
[ -f ~/.bashrc ] && . ~/.bashrc
