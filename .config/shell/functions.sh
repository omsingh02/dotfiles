# Functions that have to be functions because they change the shell itself (cd). Every other shell helper is a command in
# ~/.local/bin, where it is tested (home/.local/share/shell/tests).

# LF Directory Changer: quitting lf drops you in the last visited directory
lfcd() {
    local tmp dir
    tmp=$(mktemp -p "$XDG_RUNTIME_DIR" lf-lastdir.XXXXXX) || return
    command lf -last-dir-path="$tmp" "$@"
    dir=$(cat "$tmp")
    rm -f "$tmp"
    if [ -d "$dir" ] && [ "$dir" != "$(pwd)" ]; then
        cd "$dir" || return
    fi
}
