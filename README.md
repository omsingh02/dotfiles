# dotfiles

The desktop part of my Arch Linux machine: Hyprland, Waybar, foot, fuzzel, mako, zsh, Neovim and a few small tools. Plain files, laid out so that GNU Stow can link them into `$HOME`.

This is a curated copy. The machine itself is rebuilt from a private repository that also holds services, scripts, backups and credentials handling; none of that is here, and nothing in this repo is a secret.

## What is in here

| Path | What |
|---|---|
| `.config/hypr/` | Hyprland (Lua config, one module per concern under `conf/`), hypridle, hyprlock |
| `.config/waybar/` | Bar layout and style |
| `.config/foot/`, `fuzzel/`, `mako/` | Terminal, launcher, notifications |
| `.config/shell/`, `.zshenv`, `.bashrc` | zsh (`ZDOTDIR` points at `.config/shell`), aliases, functions |
| `.config/nvim/` | Neovim |
| `.config/mpd/`, `ncmpcpp/`, `cava/`, `mpv/`, `imv/`, `zathura/`, `lf/` | Music, video, images, PDFs, files |
| `.config/btop/`, `fastfetch/`, `fontconfig/`, `git/` | Smaller things |
| `.config/theme/templates/` | Colour templates. A script of mine fills them in from the wallpaper; the script is not in this repo, so Waybar's `colors-waybar.css` import has nothing to read until you provide your own |

## What is not

- **My scripts and services.** Keybinds and the bar call programs in `~/.local/bin` that are not here, so some keys will do nothing on your machine.
- **Identity.** `.config/git/config` includes a `config.local` for name, email and signing key; create your own.
- **Paths.** A few files hard-code `/home/faulter`. Search for it before you use them.

## Use

```sh
git clone https://github.com/omsingh02/dotfiles ~/dotfiles
cd ~/dotfiles
stow --no-folding -t ~ .     # links each file into $HOME; use --simulate first
```

Read a file before you use it. These are my machine's settings, not a framework, and none of it is meant to be installed blind.

MIT licensed.
