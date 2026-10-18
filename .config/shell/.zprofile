# Login shell hook: ~/.zprofile is a link to this file and ~/.bash_profile sources it.
# The environment is defined once, in ~/.config/environment.d/*.conf and /etc/environment. The user manager reads those
# itself; a login shell loads the same definitions here (the generator prints shell-quoted KEY=VALUE lines), so Hyprland
# and everything it starts see exactly what the units see.
set -a
# shellcheck source=/dev/null
. <(/usr/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)
set +a

# Auto-start Hyprland on TTY1
if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" && "$(tty)" == "/dev/tty1" ]]; then
    exec start-hyprland
fi
