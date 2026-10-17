# dotfiles

My Arch Linux and Hyprland setup: shell, editor, terminal, launcher, notifications, lock screen and a few small scripts. Plain files, deployed with GNU Stow.

[SCREENSHOT: your desktop, one image]

## What is in here

| Path | What |
|---|---|
| `.config/hypr/` | Hyprland, hypridle and hyprlock |
| `.config/nvim/` | Neovim |
| `.config/shell/` | zsh and shared shell config |
| `.config/foot/`, `fuzzel/`, `mako/` | Terminal, launcher, notifications |
| `.config/mpd/`, `ncmpcpp/`, `cava/` | Music |
| `.local/bin/` | Small scripts |

## Use

```sh
git clone https://github.com/omsingh02/dotfiles ~/dotfiles
cd ~/dotfiles
stow --no-folding .      # symlinks each file into $HOME
```

Read a file before you use it. These are my machine's settings, not a framework, and none of it is meant to be installed blind. Secrets are kept out of this repo.

MIT licensed.
