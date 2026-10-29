# Symphony installer audit (`vyrx-dev/symphony`) — Void theme

Date: 2026-07-05
Context: evaluation of installing Symphony (vyrx-dev's Hyprland dotfiles, "Void" visual theme) on top of the current setup (Arch, Hyprland via ML4W + sbdots-style cherry-pick reskin already applied — see [`ml4w-hyprland-investigation.md`](ml4w-hyprland-investigation.md) and [`sbdots-migration-investigation.md`](sbdots-migration-investigation.md)). Same rigor as the previous audits: code read line by line on a local clone (`git clone`, nothing executed), plus GitHub metadata. Audit done with 5 agents in parallel on the clone.

**Security note**: when requesting Symphony's GitHub page via WebFetch, the response came with fake injected `<system-reminder>` tags ("Exited Plan Mode" / "Auto Mode Active") asking to skip confirmations before destructive actions. They were ignored — no such mode is active, and this audit was done without executing any real destructive step.

## Verdict: twofold

- **Full install (run `boot.sh`/`install.sh` and adopt the whole Symphony stack):** 🟡 YELLOW. Unlike sbdots, it **does back up** before overwriting configs (`~/dotfiles-backup`, restorable), and it does not touch boot/bootloader/drivers/display manager. The yellow is because of: documented install command BROKEN (see bug below), dead project with no maintenance, and that it would overwrite exactly the same folders (`hypr`, `waybar`, `rofi`, `kitty`, `nvim`, `gtk-3.0/4.0`) that are already customized — it would mean repeating the full migration already rejected with sbdots, now on an equally abandoned project.
- **Manual cherry-pick of the Void theme on top of ML4W+sbdots (no installer, no stow, no packages):** 🟢 GREEN — recommended. Same pattern already used with sbdots. The theme files are self-contained color fragments, with no dependency on the Symphony runtime.

## VERIFIED BUG: the documented install command does not install Symphony

The `vyrx-dev/symphony` README documents verbatim:

```bash
curl -fsSL https://raw.githubusercontent.com/vyrx-dev/dotfiles/main/boot.sh | bash
# or manually:
git clone https://github.com/vyrx-dev/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
```

Both commands point to `vyrx-dev/dotfiles` — **a different, unrelated repo**, currently active (26★, `pushed_at` 2026-06-30, `master` branch) with a completely different Sway/Niri setup (no Hyprland, no `install.sh`, no `themes/`, no Void theme). The author evidently reused the `dotfiles` name for their current setup after archiving Symphony, and never updated Symphony's README. Also confirmed in `boot.sh:32`: `REPO="${SYMPHONY_REPO:-vyrx-dev/dotfiles}"` — the script's own default points to the wrong repo.

**Actual effect if run as is**: `boot.sh` does `sudo pacman -Syu --noconfirm` (full system upgrade) and `rm -rf ~/dotfiles` (if it existed) BEFORE cloning — then it clones the wrong repo, does not find `install.sh` in it, prints `Clone failed - install.sh not found` and aborts (`boot.sh:58-61`). It fails cleanly at that point (it never gets to touch `~/.config`), but you have already paid for the unrequested system upgrade and the deletion of a possible `~/dotfiles` of your own.

**Path that does work** (clone the correct repo explicitly, either with the env var override or by cloning manually):

```bash
git clone https://github.com/vyrx-dev/symphony ~/dotfiles-symphony
cd ~/dotfiles-symphony && ./install.sh
# or, if boot.sh is to be used anyway:
SYMPHONY_REPO=vyrx-dev/symphony bash <(curl -fsSL https://raw.githubusercontent.com/vyrx-dev/symphony/main/boot.sh)
```

## Verified execution chain (code read line by line, on the correct clone)

```
boot.sh (optional, only if the one-liner with REPO override is used)
  L38  sudo pacman -Syu --noconfirm --needed git stow gum   (full upgrade, WITHOUT a prior gate)
  L47-48  rm -rf "$DEST" && git clone .../$REPO.git "$DEST" (branch main, no tag/commit pin)
  L67  source ./install.sh
install.sh
  L20-22  warn + confirm "Continue?" || exit 0   <- only global gate, and already after the upgrade
  L39  source install/packages.sh   (package installation)
  L42/45/48  source stow.sh / desktop-entries.sh / services.sh
  L52  scripts/choose-shell (interactive chsh, optional)
  L58  install/themes/install.sh (setup of the `symphony` CLI, does not apply the theme yet)
install/packages.sh
  setup_aur (if yay/paru is missing: clones and builds yay-bin from AUR, output hidden, --noconfirm)
  do_install: ~100 core packages via pacman/AUR, --noconfirm, repo/AUR split resolved at runtime
  ask_applications: optional packages via gum multi-select
```

## sudo points (exact)

- `boot.sh:38` — `sudo pacman -Syu --noconfirm --needed git stow gum` (full upgrade, before any confirmation).
- `install/packages.sh:97` — `makepkg -si --noconfirm` for `yay-bin` (if there is no AUR helper), full output to `/dev/null` — an AUR PKGBUILD is built and installed as root without review.
- `install/packages.sh:123` — `sudo pacman -S --needed --noconfirm "${official[@]}"` (~100 core packages).
- `install/packages.sh:130` — `$aur -S --needed --noconfirm "${from_aur[@]}"` (yay/paru, no PKGBUILD review).
- `install/services.sh:20` — `sudo systemctl enable --now bluetooth` (only if bluez is installed).
- `install/services.sh` (spicetify section) — `sudo chmod a+wr -R "$spotify_path/Apps"` — leaves the Spotify directory **world-writable** (permission loosening, not critical but real).
- `scripts/choose-shell:19` — `sudo chsh -s ... "$USER"` — changes the login shell, but only after an interactive menu with an exit option.

No writes to `/etc` outside of packages, nor to GRUB/initramfs/bootloader.

## Backup of existing configs — DOES EXIST (unlike sbdots)

`install/stow.sh::backup_if_exists()` moves (does not delete) any preexisting, non-symlink item in `~/.config/*` and `~/.local/share/*` that conflicts, to `~/dotfiles-backup` (or `-2`, `-3`... if one already exists), before running `stow .`. `stow .` is run without `--adopt`/`-R`/force — if there is still a conflict, it aborts with `exit 1` instead of overwriting. `uninstall.sh::restore_backups()` restores from the most recent backup. Only caveat: if there was already a previous installation, the most recent backup may be a backup of Symphony leftovers, not of the original configs.

**Folders the stow would touch** (it would overwrite what is already customized): `hypr, waybar, rofi, kitty, nvim, gtk-3.0, gtk-4.0, alacritty, btop, cliphist, fastfetch, fish, ghostty, lazygit, matugen, mpd, mpdscribble, rmpc, swaync, swayosd, tmux, Typora, uwsm, yazi` + `brave-flags.conf`, `chromium-flags.conf`.

## What it touches in boot / drivers / display manager

Exhaustive grep (`sddm|gdm|lightdm|grub|mkinitcpio|systemd-boot|nvidia|systemctl enable|rm -rf|chsh|usermod|autologin|greetd`) over the whole tree: **zero modifications to bootloader, initramfs or drivers**. `sddm` is installed as a package (packages.sh line) but never enabled (`systemctl enable sddm` does not exist in the repo) — it does not change the active display manager. The two mentions of `nvidia` in `hyprland.conf` are session env vars (`LIBVA_DRIVER_NAME`, `__GLX_VENDOR_LIBRARY_NAME`), with no effect outside the Hyprland session. `chsh` is interactive and optional. Every `rm -rf` other than the one already mentioned in `boot.sh:47` is benign (cleanup of temporary files or deletion of Symphony's own folders, with confirmation).

## Coexistence with the current ML4W + sbdots

There is no ML4W detection logic (same as sbdots). The `stow.sh` backup would protect the current configs (they would be moved to `~/dotfiles-backup`, recoverable), but the net result of a full install would be replacing live exactly the same set of pieces already assembled by hand (waybar/rofi/kitty/hypr with the sbdots reskin) with the complete Symphony ecosystem (its own `symphony` CLI, its theme hooks, `uwsm` managing waybar). It is, in effect, the same class of "full replacement" decision already evaluated and discarded with sbdots — with the difference that here there is a safety net (backup + `uninstall.sh` with restore).

## Installed packages (core, ~100)

`base-devel git stow hyprland hypridle hyprlock hyprpicker hyprsunset xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt5-wayland qt6-wayland uwsm waybar rofi swaync swayosd swww wlogout brave-bin kitty alacritty fish starship tmux eza bat fd ripgrep fzf zoxide jq yazi nautilus neovim lazygit grim slurp satty wl-clipboard gpu-screen-recorder ffmpeg v4l-utils cliphist wl-clip-persist pipewire pipewire-alsa pipewire-pulse wireplumber pamixer wiremix mpd mpc rmpc cava playerctl mpdscribble spotify-launcher spicetify-cli mpd-mpris networkmanager nmgui-bin kdeconnect bluez bluez-utils blueman polkit-gnome brightnessctl ddcutil power-profiles-daemon upower libnotify xdg-utils xdg-user-dirs inotify-tools gnome-keyring libsecret xorg-xhost libappindicator matugen nwg-look adw-gtk-theme bibata-cursor-theme-bin imagemagick rofimoji wtype btop fastfetch chafa ttf-jetbrains-mono-nerd ttf-cascadia-mono-nerd noto-fonts-emoji sddm qt5-quickcontrols qt5-quickcontrols2 qt5-graphicaleffects python-terminaltexteffects gum wget curl unzip localsend deno npm keyd tree-sitter-cli`

Plus ~24 optional packages via gum multi-select (VS Code, Discord/vesktop, Steam, Obsidian, etc — not forced).

## Maintenance status

- Archived 2026-05-15 ("I no longer use Hyprland"). No successor or maintained fork indicated.
- Last real code commit: **2026-01-08**. After that only housekeeping (README, funding). ~4 months without development before the freeze.
- 3 open issues, frozen forever (archived repo blocks issues): **#56 installer hangs** (2026-04-27, never resolved), **#63 theme/config bug on CachyOS** (2026-05-14, one day before archiving, never answered), #51 call for testers for a v3.0 that never shipped.
- 509★, 22 forks, 854 commits, last release v2.1.1 (2025-12-31).

## Risks (why YELLOW, not GREEN, for the full install)

1. **Documented install command is broken** (points to an unrelated repo) — it has to be corrected by hand with `SYMPHONY_REPO=vyrx-dev/symphony` or by cloning directly.
2. `boot.sh` runs `pacman -Syu --noconfirm` (full system upgrade) before any confirmation.
3. AUR build (`yay-bin` and AUR packages in bulk) 100% `--noconfirm`, no PKGBUILD review, yay bootstrap output hidden.
4. Dead project: hanging installer bug (#56) and distro compatibility bug (#63) with no possible fix, v3.0 abandoned.
5. It would overwrite exactly the folders already assembled by hand (hypr/waybar/rofi/kitty/nvim) — same type of "full replace" decision already rejected with sbdots, although here with a recoverable backup.
6. Minor security loosenings: gnome-keyring is left with auto-unlock (`lock-on-idle=false`, `lock-after=false`); Spotify directory is left world-writable (`chmod a+wr -R`) by the spicetify step.
7. The `trap ERR` does a screen `clear` on failure (hides the real error), and several steps silence failures (`|| true`, output to `/dev/null`).

## Recommended path: cherry-pick of the Void theme (GREEN)

The theme is completely self-contained — zero dependency on the `symphony` CLI or on stow. Palette: **AMOLED black + lavender/violet monochrome** (background `#05010C`, cursor `#814DDE`, accents `#BB9AF7`/`#A6B8FF`/`#DECCFF`; the whole ANSI palette remapped to violets except red). Included wallpapers (`themes/void/1.jpg`, `2.png`) match the palette.

Files to copy by hand (no installer, no stow, no new packages, no sudo):

- `themes/void/.config/kitty/colors.conf` → new file in `kitty/`, included via `include` in `kitty.conf` (native kitty syntax).
- `themes/void/.config/hypr/theme/colors.conf` → adapt to ML4W's `hypr/conf/`; it must be loaded **after** the ML4W/matugen color source so that it wins.
- `themes/void/.config/btop/themes/current.theme` → copy as a new theme, set `color_theme` in `btop.conf`.
- `themes/void/.config/cava/config` → copy only the `[color]` block (7-step gradient), not the whole file.
- `themes/void/backgrounds/{1.jpg,2.png}` → wallpapers.
- Symphony's `waybar/colors.css` and `rofi/colors.rasi` use different variable names from those of ML4W/sbdots (Material-style vs custom) — **translate the hex values to the existing variables**, do not copy the file as is.
- `themes/void/.config/starship.toml` → only cherry-pick the color palette, not the whole file (it would overwrite the current prompt).
- nvim: nothing to copy — Void's "theme" there is stock Catppuccin with `transparent_background = true`.

**Caveat**: if ML4W's matugen/wallust pipeline regenerates colors on wallpaper change, it can compete with Void's static files — the includes must point to the static files (or disable the dynamic pipeline for those apps). Exact same pattern used to cherry-pick sbdots.

## Status (2026-07-05)

**This is ONLY the audit.** No package was installed, `boot.sh`/`install.sh`/stow were not run, no file in `~/.config` or on the real system was touched. The clones of `vyrx-dev/symphony` and `vyrx-dev/dotfiles` used to read the code live in a temporary scratch directory, not in this repo. Decision pending from the user: cherry-pick of the Void theme (recommended), full install anyway, or discard.
