# dotfiles

Personal Linux dotfiles managed with a bare Git repo:

```sh
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
```

This repo tracks the shell, Git defaults, Hyprland, Waybar, Kitty, Neovim, Yazi, and small helper configs needed to reproduce the environment on a new machine.

## Restore on a new machine

Clone the bare repository and check it out into `$HOME`:

```sh
git clone --bare git@github.com:caiohenrqq/dotfiles.git "$HOME/.dotfiles"
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
config checkout
config config status.showUntrackedFiles no
```

Install packages from the manifests in `packages/`, then create your local Git identity file:

```sh
cp ~/.gitconfig.local.example ~/.gitconfig.local
```

Edit `~/.gitconfig.local` with your real Git name and email.

## Package restoration

Core packages:

```sh
sudo pacman -S --needed - < packages/pacman.txt
```

AUR packages:

```sh
yay -S --needed - < packages/aur.txt
```

Flatpak apps, if used:

```sh
xargs -r flatpak install -y < packages/flatpak.txt
```

## Post-install

- Install Oh My Zsh and Powerlevel10k.
- Start `nvim` once to install plugins from `lazy-lock.json`.
- Run `ya pkg install` in Yazi if package sync is needed.
- Confirm `~/.gitconfig.local` contains the right Git name and email.
