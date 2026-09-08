# Custom shell functions

# Select and edit scripts in ~/.local/bin
se() {
    local choice
    choice="$(find ~/.local/bin -mindepth 1 -printf '%P\n' 2>/dev/null | fzf)"
    [ -n "$choice" ] && [ -f "$HOME/.local/bin/$choice" ] && $EDITOR "$HOME/.local/bin/$choice"
}

# Download and process music from YouTube playlist
ffc() {
    yt-dlp --download-archive "$HOME/music/yt-staging/downloaded_tracks.txt" \
        -f bestaudio -x --audio-format best --audio-quality 0 \
        -o "$HOME/music/yt-staging/%(playlist_index)s - %(title)s.%(ext)s" \
        --exec "$HOME/.local/bin/songs/.venv/bin/python $HOME/.local/bin/songs/get.py {}" \
        "https://music.youtube.com/playlist?list=PL0WzpuX2jUBC6JE4PkgL0GnjV9oRUEiVT"
}

# LF Directory Changer: quitting lf drops you in the last visited directory
lfcd() {
    local tmp="$(mktemp)"
    command lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        local dir="$(cat "$tmp")"
        rm -f "$tmp"
        if [ -d "$dir" ] && [ "$dir" != "$(pwd)" ]; then
            cd "$dir"
        fi
    fi
}

# Captive Portal Bypass for Wi-Fi
portal() {
    WIFI_IF="wlp3s0"

    if [ "$1" == "open" ]; then
        echo -e "\e[1;33m[+] Opening Captive Portal Bypass...\e[0m"

        GW=$(ip route | awk -v iface="$WIFI_IF" '/default/ && $0 ~ iface {print $3}')

        if [ -z "$GW" ]; then
            echo -e "\e[1;31m[-] Error: No default route found on $WIFI_IF. Connect to the Wi-Fi network first.\e[0m"
            return 1
        fi

        sudo resolvectl dns "$WIFI_IF" "$GW"
        sudo resolvectl domain "$WIFI_IF" "~."
        sudo resolvectl dnsovertls "$WIFI_IF" no

        echo -e "\e[1;32m[!] Portal mode OPEN.\e[0m"
        echo -e "[!] Open your browser and go to: \e[4;36mhttp://neverssl.com\e[0m"

    elif [ "$1" == "close" ]; then
        echo -e "\e[1;34m[+] Closing bypass and restoring NextDNS...\e[0m"
        sudo nmcli device reapply "$WIFI_IF"
        echo -e "\e[1;32m[!] Portal mode CLOSED. Network is encrypted.\e[0m"
    else
        echo "Usage: portal {open|close}"
    fi
}

# Network & DNS Health Check
netcheck() {
    echo -e "\e[1;34m--- DNS STATUS (NextDNS) ---\e[0m"
    resolvectl status | grep -A 5 "Global"

    echo -e "\n\e[1;32m--- TAILSCALE STATUS ---\e[0m"
    tailscale status | grep -v "offline" || echo "All peers offline."

    echo -e "\n\e[1;33m--- INTERFACE STATUS (br0) ---\e[0m"
    ip -4 addr show br0 | grep inet || echo "br0 is offline/disabled."

    echo -e "\n\e[1;35m--- CONNECTIVITY TEST ---\e[0m"
    ping -c 1 google.com > /dev/null 2>&1 && echo "Internet: ONLINE" || echo "Internet: OFFLINE"
}

# Auto-Compile & Watch for C/C++
ac() {
    if [ -z "$1" ]; then
        echo -e "\e[31m[!] Usage: autoc <filename.c | filename.cpp>\e[0m"
        return 1
    fi

    local FILE="$1"
    local BASE="${FILE%.*}"
    local EXT="${FILE##*.}"

    if [ "$EXT" = "c" ]; then
        local COMPILER="gcc"
    elif [ "$EXT" = "cpp" ] || [ "$EXT" = "cxx" ]; then
        local COMPILER="g++"
    else
        echo -e "\e[31m[!] Error: '$FILE' is not a .c or .cpp file.\e[0m"
        return 1
    fi

    local FLAGS="-Wall -Wextra"

    echo -e "\e[34m[*] Watching $FILE...\e[0m"

    ls "$FILE" | entr -c sh -c "
        echo -e '\e[33m[*] Compiling $FILE with $COMPILER...\e[0m'

        if $COMPILER $FLAGS '$FILE' -o '$BASE'; then
            echo -e '\e[32m[+] Build successful. Running binary:\e[0m'
            echo -e '\e[90m----------------------------------------\e[0m'

            './$BASE'

            echo -e '\n\e[90m----------------------------------------\e[0m'
            echo -e '\e[90mWaiting for next save...\e[0m'
        else
            echo -e '\n\e[31m[!] Build failed. Fix errors and hit save to retry.\e[0m'
        fi
    "
}
