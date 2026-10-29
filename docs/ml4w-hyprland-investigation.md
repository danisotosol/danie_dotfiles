# ML4W Dotfiles (Hyprland) investigation — coexistence with KDE Plasma

Date: 2026-07-05
Context: Hyprland installation via the ML4W project (`mylinuxforwork/dotfiles`) on Arch Linux, with KDE Plasma already installed. Goal: have them coexist side by side without breaking Plasma. HyDE and JaKooLit were ruled out earlier because they modify GRUB/SDDM/NVIDIA drivers.

## Verdict: YELLOW

Safe to install alongside Plasma. It does not touch GRUB, systemd-boot, mkinitcpio, NVIDIA drivers, SDDM or GDM. It does replace user dotfiles (`.bashrc`, `.zshrc`, GTK/Qt themes) with an automatic backup beforehand, and chains a couple of remote scripts not pinned to a fixed version.

## Command executed

```bash
bash <(curl -s https://ml4w.com/os/stable)
```

This command serves a real bash script (not a landing page) of 68 lines.

## Verified execution chain (code read line by line)

1. `https://ml4w.com/os/stable` → bootstrap script.
2. Clones `mylinuxforwork/ml4w-dotfiles-installer` **pinned to tag `0.2.5`**, runs `make install` (copies only to `~/.local/bin` and `~/.local/share`, no sudo — Makefile verified).
3. Runs:
   ```bash
   ml4w-dotfiles-installer --install https://raw.githubusercontent.com/mylinuxforwork/dotfiles/main/hyprland-dotfiles-stable.dotinst
   ```
4. The `.dotinst` (JSON) points to `mylinuxforwork/dotfiles` branch `main` (no tag), subfolder `dotfiles/`. The installer runs in order:
   - `setup/preflight-arch.sh`
   - installs package lists (`setup/dependencies/packages`, `packages-arch`)
   - `setup/post-arch.sh`
   - creates dotfile symlinks (with backup beforehand)
   - `setup/migration.sh`

## Sudo points (exact)

- Bootstrap: `sudo pacman -S --needed --noconfirm git make curl jq`
- `lib/helpers.sh` (if `gum` is missing): `sudo pacman -S --needed --noconfirm gum`
- `setup/preflight-arch.sh`: `sudo pacman --noconfirm -S "base-devel"`, and if `swww` is installed: `sudo pacman -Rns --noconfirm swww` (replaced by `awww`)
- `setup/_fonts.sh`: `sudo cp -rf .../setup/fonts/* /usr/share/fonts` — the only write to a system directory in the Arch path
- AUR package installation: `yay/paru -S --needed --noconfirm` (no sudo) or `sudo pacman -S --needed --noconfirm` as fallback

Everything uses `--noconfirm`, but there is a human gate before starting: `gum confirm "Do you want to proceed with the installation?"` with the full profile summary (name, id, version, source).

## Backup of existing configs

Before creating each symlink (`lib/utils.sh::create_symlink`):

```bash
if [ -e "$target" ]; then
    warn "  - Existing file/folder found at $target. Creating backup..."
    mkdir -p "$backup_dir"
    cp -a "$target" "$backup_dir/"
    rm -rf "$target"
fi
ln -s --relative "$source" "$target"
```

Backups are kept in `~/.mydotfiles/backups/<profile>/<timestamp>/`. The original is deleted after being copied — recoverable only from that backup.

## What it does NOT touch (why it is not RED)

Exhaustive grep (`sddm|gdm|grub|mkinitcpio|systemd-boot|nvidia|lightdm|systemctl`) over the complete `mylinuxforwork/dotfiles` and `ml4w-dotfiles-installer`: **zero hits in the Arch path**. The only related hit: `sddm-qt6` in `packages-opensuse` (openSUSE only). There is no `systemctl enable` in any script of the Arch path. The "Hyprland" session in SDDM appears because the official Arch `hyprland` package ships `/usr/share/wayland-sessions/hyprland.desktop` — a standard additional session; the Plasma one remains intact.

## Installed packages

Common: wget, curl, git, rsync, unzip, tar, jq, flatpak, vim, inotify-tools, udisks2, gvfs, udiskie, hyprpaper, hyprlock, hypridle, hyprpicker, xdg-desktop-portal-hyprland, kitty, vlc, nwg-dock-hyprland, waybar, rofi, nwg-look, pavucontrol, neovim, blueman, qt6ct, nautilus, gnome-text-editor, firefox, xdg-user-dirs, xdg-desktop-portal-gtk, figlet, fastfetch, htop, xclip, zsh, fzf, brightnessctl, tumbler, slurp, cliphist, grim, breeze, tesseract, wl-clipboard, btop, cargo, eza, libsecret.

Arch: hyprland, hyprsysteminfo, hyprshutdown, libnotify, qt5-wayland, qt6-wayland, gnome-themes-extra, uwsm, python-pip, python-gobject, python-screeninfo, nm-connection-editor, network-manager-applet, imagemagick, polkit-gnome, hyprsunset, grimblast-git, pacman-contrib, loupe, power-profiles-daemon, swaync, python-pywalfox, tesseract-data-eng, otf-font-awesome, ttf-firacode-nerd, ttf-jetbrains-mono-nerd, qt6-svg, qt6-virtualkeyboard, qt6-multimedia-ffmpeg, gvfs-mtp, quickshell, awww, matugen, nwg-displays.

## Risks / things to watch (why YELLOW and not GREEN)

1. Replaces `~/.bashrc` and `~/.zshrc` with symlinks to ML4W versions (with backup beforehand). If there are shell customizations, merge them manually afterwards from the backup.
2. Symlinks in `~/.config`: gtk-3.0, gtk-4.0, `.gtkrc-2.0`, qt6ct, xsettingsd, kitty, rofi, waybar, btop, fastfetch, fish, vim, etc. It does not touch anything from Plasma (`kdeglobals`, `kwinrc`, `plasma*`), but it changes the GTK/Qt theming of GTK apps inside the current Plasma session. Cosmetic and reversible from the backup.
3. Remote scripts not pinned to a version: `post-arch.sh` runs `curl -s https://ohmyposh.dev/install.sh | bash` and `bash <(curl -s .../ml4w-dotfiles-settings/main/setup.sh)` (the latter only installs to `~/.local/bin`, no sudo). The dotfiles themselves are cloned from `main`, not from a tag — what was audited today may differ slightly from what runs in the future.
4. Uninstalls `swww` if it was present, and installs `yay` or `paru` if there was no AUR helper.

## Status after execution (2026-07-05)

The user ran the command on their real machine; the final output was `success "Setup process finished!"` — the last line of the bootstrap (`set -e` implies that if anything had failed earlier, it would not have been printed). Installation completed successfully.

### Pending next steps
- Reboot the system.
- In SDDM, choose the "Hyprland" session to test it (the Plasma one is still available).
- Check `~/.mydotfiles/backups/<profile>/<timestamp>/` if anything in shell/theming ended up different from expected.
