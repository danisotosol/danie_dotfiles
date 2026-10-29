# sbdots installer audit (`sbalghari/sbdots`) — possible migration from ML4W

Date: 2026-07-05
Context: evaluation of dropping ML4W and migrating the current Hyprland setup (Arch, Hyprland 0.55.4, ML4W + manual sbdots-style reskin already applied) to the full sbdots framework by running its installer. sbdots is not a collection of dotfiles to copy by hand: it is an Arch package (PKGBUILD) + Python CLI (Typer) with two entrypoints (`sbdots` initializer, `sbdotsctl` runtime control), two user systemd daemons (`sbdots-actions`, `sbdots-clipboard-listener`), a C++ socket client binary, and dotfiles in `/usr/share/sbdots`. The Hyprland config is in Lua format (`hyprland.lua`, `hl.on`/`hl.exec_cmd` API, introduced in Hyprland 0.55 — compatible with the installed 0.55.4; `hyprland.lua` takes precedence over `hyprland.conf`). Theming 100% matugen. Explicitly Arch-only (`pacman -Qq` and `yay -S` hardcoded). GPL-3.0 license, declared version 0.0.3-alpha.

## Verdict: 🔴 RED

RED for a full migration (running the installer on top of the live system). The red is NOT due to malice — the code is small, readable, with nothing shady: zero touches to boot/drivers/display manager, sudo only for pacman/yay, services user-scope only. The red is due to viability and data loss: project frozen by the author's own admission, verifiably broken installer (`sbdots install` does not exist), and destructive deletion of 17 `~/.config` directories **without backup** (literal comment `# TODO: Add backups` in the code), which would destroy the live ML4W installation and also the manual reskin already done. The current strategy of cherry-picking sbdots configs/CSS on top of the ML4W plumbing remains GREEN and is the best possible use of a frozen repo.

## Command / entrypoint

The README **does not publish any install command** — it only says "You could use the install.sh but it isn't fully tested, so use it at your own risk". The script exists at the repo root:

```bash
# curl|bash equivalent, NEVER documented by the author:
curl -fsSL https://raw.githubusercontent.com/sbalghari/sbdots/main/install.sh | bash
```

**VERIFIED BUG**: the last step of `install.sh` runs `sbdots install`, but the Python CLI only registers the `init` command (`src/sbdots/__init__.py:47-48`, the only `@cli.command()`; the installer's own cancellation message says "please run 'sbdots init'"). Typer returns "No such command 'install'" → `fail "sbdots install failed"` → the bootstrap **aborts after installing ~30 packages but before touching any dotfile**. The flow that actually works: run `install.sh` (or `makepkg` by hand) and then `sbdots init` manually.

## Verified execution chain (code read line by line)

**Phase 1 — `install.sh` (bash, `set -e`):**

1. `install_system_deps()`: `sudo pacman -S --needed --noconfirm` for git and base-devel if missing.
2. `install_yay()`: if yay is not present → `rm -rf /tmp/yay`, clone from the AUR, `makepkg -si --noconfirm`.
3. `install_aur_deps()`: `yay -S --noconfirm` loop over 14 AUR packages (full list below).
4. `download_pkgbuild()`: curl of the PKGBUILD to `/tmp/sbdots`.
5. `build()`: `makepkg -si --noconfirm` — clones the repo, builds the Python wheel + compiles `bin/sbdots-actions.cpp` with g++, and installs via pacman: CLI in `/usr/bin`, dotfiles in `/usr/share/sbdots`, defaults in `/etc/sbdots`, services in `/usr/lib/systemd/user` (does **not** enable them). Pulls in ~40 official depends.
6. `run_setup()`: `sbdots install` → **BROKEN** (the command is `init`).

**Phase 2 — `sbdots init` (`SBDotsInitializer.install()`):**

- `_validators.py::is_already_installed()`: only checks `~/Dotfiles`, `~/Wallpapers`, `~/.sbdots` — if they exist, WARN and continues anyway.
- Interactive `confirm()`.
- `ComponentsManager`, 3 steps:
  - **DotfilesInstaller (critical)**: validates sources in `/usr/share/sbdots/configs` → if `~/Dotfiles` exists **deletes it entirely** (`shutil.rmtree`, `dotfiles.py:76-78`) → copies configs to `~/Dotfiles` → verifies → `_remove_existing_configs()`: **deletes `~/.config/<X>` for 17 components without backup** (atuin, btop, cava, fastfetch, fish, gtk-3.0, gtk-4.0, hypr, kitty, matugen, neofetch, qt5ct, qt6ct, rofi, swaync, waybar, waypaper, wlogout) → `_create_links()`: symlink `~/Dotfiles/<X>` → `~/.config/<X>`.
  - **WallpapersInstaller (critical)**: copies wallpapers to `~/Wallpapers` + avatar to `~/.sbdots/.avatar`; optionally clones `github.com/sbalghari/Wallpapers` to `/tmp`.
  - **OptPackagesInstaller (non-critical)**: multiselect menu of 11 optional packages with `yay -S --noconfirm` under `SudoKeepAlive` (thread that refreshes `sudo -v` every 60s, max 30 min, `sudo -k` on exit).
- `PostInstallHooks`: `systemctl --user daemon-reload` + `systemctl --user start --now` of each `sbdots-*.service` (user scope only, start only, never enable — the CHANGELOG confirms the enable→start change was deliberate); `waypaper --restore`.
- Final message: "Please restart your PC once before using".

**Post-install runtime** (`hyprland.lua` at login): `sbdotsctl waybar --start`, hyprpolkitagent, swaync, the 2 sbdots daemons, wl-paste, udiskie, `devify` (AUR, **not in deps — silent failure**), `waypaper --restore`.

## Sudo points (exact)

Installer:

- `install.sh:49` — `sudo pacman -S --needed --noconfirm "$dep"` (git, base-devel).
- `install.sh:69` and `:105` — `makepkg -si --noconfirm` (×2: yay and sbdots-git; makepkg invokes sudo pacman internally).
- `install.sh:79` — `yay -S --noconfirm <pkg>` (×14 AUR; yay elevates with sudo internally).
- `src/sbdots/library/sudo_keep_alive.py:33` `sudo -v`, `:61` `sudo -v` in a loop every 60s (daemon thread, max 30 min), `:82` `sudo -k` — only wraps the optional package installation (`packages.py:63`).
- `src/sbdots/library/pkg_utils.py:23` — `yay -S <pkg> --noconfirm --quiet` (optional packages).

Runtime (triggered by the user afterwards):

- `src/sbdots/ctl/updates.py:72` — `sudo pacman -Syu --noconfirm`, plus `yay/paru -Syu --noconfirm`, `pacman -Rns <orphans> --noconfirm`, `pacman -Sc --noconfirm` and `reboot`, via `run_sudo_cmd` (`commands.py:123`: pexpect wrapper that detects the sudo prompt and injects the password requested by the CLI; disables the logfile during the password, but logs the output to `/tmp/sudo_output.log` — predictable path in /tmp, minor leak).
- `dotfiles/configs/waybar/scripts/installupdates.sh:47` — `sudo pacman -Syu --noconfirm`; `:59` — `sudo pacman -Rns $(pacman -Qdtq) --noconfirm` (orphan cleanup without confirmation: risky on a system with ML4W leftovers).

**Not present**: sudo on system files outside pacman, edits to `/etc` (only the PKGBUILD installs `/etc/sbdots/rich_theme.toml` as part of the package), or arbitrary privileged writes.

## What it touches in boot / drivers / display manager

Exhaustive grep over the whole tree (`*.py`, `*.sh`, `*.service`, PKGBUILD, `*.toml`, `*.conf`, `*.lua`) for `sddm|gdm|grub|mkinitcpio|systemd-boot|nvidia|lightdm|systemctl|dd|rm -rf`: **zero modifications to boot, bootloader, initramfs, drivers or display manager**.

- `sddm`: only hit in `src/sbdots/constants.py:103` — string inside `OPTIONAL_PACKAGES`; if the user selects it the package gets **installed**, but `systemctl enable sddm` is never run (there is no `systemctl enable` anywhere in the repo; the CHANGELOG records the fix "use start instead of enable").
- `systemctl`: `--user` scope only (`postinstall/start_service.py:36,64`; `hypr/hyprland.lua:32-35`; `hypridle.conf:25` with `systemctl suspend` on-timeout — standard idle command).
- `nvidia`: cosmetic value only in `btop.conf:267-268`.
- `rm -rf`: only `install.sh:64,73` on `/tmp/yay`.
- `gdm|grub|mkinitcpio|systemd-boot|lightdm|dd`: zero hits.
- The two `.service` files are **user** units in `/usr/lib/systemd/user`, `WantedBy=default.target`, unprivileged (the cliplistener even with `NoNewPrivileges=true` and `PrivateTmp=true`).
- There is also no `chsh`/`usermod`/autologin/greetd/xinitrc (separate grep: zero hits) — it installs fish but does not set it as the default shell.

## Backup of existing configs

**DOES NOT EXIST.** Confirmed in code: `dotfiles.py:115` has the literal comment `# TODO: Add backups` right above `_remove_existing_configs()`, which does `shutil.rmtree`/unlink of `~/.config/<component>` for the 17 components (includes `hypr`, `waybar`, `kitty`, `rofi`, `swaync`, `wlogout`, `gtk-3.0`, `gtk-4.0`, `qt5ct`, `qt6ct`, `fish`…). In addition, `dotfiles.py:76-78` deletes `~/Dotfiles` entirely if it already exists. Collateral damage: deleting `gtk-3.0` takes `~/.config/gtk-3.0/bookmarks` (file manager bookmarks) with it. There is no uninstall command, no restore, no timestamped backup like ML4W does (`~/.ml4w-backup`). If `sbdots init` fails halfway (after deleting, before symlinking), the user is left without Hyprland/waybar configs and the next session starts broken, with no automatic rollback.

## Coexistence with the current ML4W

**It cannot coexist and does not migrate**: sbdots completely ignores the existence of ML4W. The only prior check looks for old SBDots installations, and even when it finds them it only warns and continues. Running it on top of the current system:

1. **Packages**: uninstalls nothing from ML4W; installs ~55 of its own packages on top. Large overlap (waybar, rofi, swaync, kitty, hyprlock, hypridle are already there). Likely conflict: `qt6ct-kde`/`qt5ct-kde` (AUR) against ML4W's vanilla `qt6ct`/`qt5ct` — with `yay --noconfirm` it can abort install.sh halfway through the package phase. Adds a second icon theme (tela-circle + breeze), a second cursor (bibata), fish+starship, and `awww` as a wallpaper daemon coexisting with ML4W's (they do not start at the same time, but both remain installed).
2. **Configs**: `sbdots init` deletes without backup `~/.config/hypr`, waybar, rofi, swaync, wlogout, kitty and 11 more — destroys the live ML4W installation **and also the manual reskin already done** (the tuned waybar/rofi/swaync/wlogout/kitty CSS lives exactly in those folders). ML4W is left decapitated but not removed: `~/.ml4w*`, the ML4W apps (settings, welcome, sidebar), their packages and their cache survive — and they are a trap: any ML4W "restore/update" utility run afterwards will try to rewrite `~/.config`, overwriting the sbdots symlinks.
3. **Session**: does not touch SDDM or the session — login continues through the current login; Hyprland 0.55.4 finds `hyprland.lua` (precedence over `.conf`) and loads the full sbdots world: different keybinds, `sbdotsctl` managing waybar, matugen instead of the ML4W theme engine. There are no "two waybars" at runtime because the replacement is total, but there are two ecosystems installed at the package level.
4. **The real path**: since install.sh breaks at `sbdots install`, the most likely scenario today is: it installs ~30-55 packages, aborts, and does not touch a single config — a half-done migration that has to be finished by hand with `sbdots init`, taking on all the risks of deletion without backup. A clean migration would require: full manual backup of `~/.config`, uninstalling ML4W with its own uninstaller first, and only then sbdots — the installer does none of that.

## Installed packages

**install.sh via yay (14, AUR)**: nautilus, nautilus-code, nautilus-copy-path, nautilus-hide, matugen-bin, python-inquirerpy (vestigial — zero imports in `src/`), qt6ct-kde, qt5ct-kde (potential conflict with ML4W's qt6ct/qt5ct), hyprshade, bibata-cursor-theme-bin, aur-check-updates, waypaper, wlogout, neofetch (upstream archived).

**PKGBUILD depends (~40, official repos — awww/uwsm/tela/hyprpolkitagent verified against archlinux.org)**: atuin, power-profiles-daemon, hyprpolkitagent, breeze-icons, breeze-gtk, awww, blueman, brightnessctl, btop, eza, fastfetch, figlet, fish, gnome-keyring, hypridle, hyprlock, hyprpicker, hyprshot, kitty, kwalletmanager, noto-fonts, pacman-contrib, pavucontrol, polkit-kde-agent, python-pexpect, python-psutil, python-pyfiglet, python-requests, python-rich, python-setproctitle, python-typer, rofi, starship, swaync, tela-circle-icon-theme-standard, ttf-dejavu, ttf-jetbrains-mono(+nerd), udiskie, uwsm, waybar, wl-clipboard. makedepends: git, python-build/installer/wheel/setuptools, gcc.

**Optional, user's choice (11)**: visual-studio-code-bin, vlc, smile, sddm, obs-studio, mission-center, freedownloadmanager-bin, loupe, libreoffice-fresh, gnome-text-editor, ark.

**Uninstalls nothing**: zero `pacman -R` in the installer (the only `-Rns` is the orphan cleanup in the runtime update tools, dangerous post-migration because ML4W's orphaned deps would fall into it). Broken deps detected: `devify` (hyprland.lua runs it at startup, not declared — silent failure) and `gum` (`installupdates.sh` requires it and exits with an error if missing; not in depends).

## Maintenance status

Confirmed with fresh evidence (GitHub API, queried today 2026-07-05): the repo **is not archived** (`archived: false`, `disabled: false`), but development is **stopped by the author's explicit statement** in the `main` README (literal text): *"[!WARNING] Further Development is stopped at the moment. You could use the install.sh but it isn't fully tested, so use it at your own risk."*

- Last push: 2026-06-18 18:18 UTC — and it is precisely "Update README.md", the commit where the freeze is presumably announced.
- Last real code work: 2026-06-08 ("merge branch dev into main", "style: improve waybar and swaync look"). ~4 weeks without activity; freeze announced ~2.5 weeks ago.
- Open issues: 0. Small project: 83 stars, 4 forks, a single maintainer (Saifullah Balghari).
- The latest issues/PRs (#20-#27, May-June 2026) show a large refactor that had not fully settled (migration to Lua, to systemd services, to matugen), topped off with commits "fix incomplete/incorrect stuff introduced by previous refactors". The freeze caught the project just out of that restructuring, and the `sbdots install` vs `init` bug was left unfixed.
- Version: 0.0.3-alpha in `pyproject.toml` (0.1.0 in CHANGELOG, 2026-06-01) — alpha by its own admission.

## Risks (why RED)

1. **Project dead by its own admission**: freeze declared in the README, last real code 2026-06-08, a single maintainer. Migrating the daily driver to a framework with its own daemons, its own CLI and the brand-new Hyprland 0.55 Lua format, with nobody to fix future Hyprland/waybar breakages, is taking on unsupported debt.
2. **Verifiably broken installer**: `install.sh` ends in `sbdots install`, a nonexistent command (the CLI only registers `init`). Run as is: it installs ~30-55 packages and aborts. The README itself warns "isn't fully tested, use at your own risk".
3. **Destructive deletion without backup**: `sbdots init` does rmtree of 17 `~/.config` directories and of `~/Dotfiles` entirely, with a literal `# TODO: Add backups` in the code. Destroys the live ML4W installation and the manual reskin already done. If it fails halfway, the next session starts broken with no rollback. ML4W at least backs up before overwriting; this does not.
4. **Zero migration awareness**: does not detect or clean up ML4W. `~/.ml4w*`, orphaned ML4W apps and packages would remain, with the trap that any ML4W tool run afterwards would overwrite the sbdots symlinks; and the sbdots update tools run `pacman -Rns $(pacman -Qdtq) --noconfirm`, which post-migration could remove ML4W's orphaned deps without asking.
5. **Likely package conflicts**: `qt6ct-kde`/`qt5ct-kde` (AUR) vs ML4W's `qt6ct`/`qt5ct` can abort install.sh with `--noconfirm`; minor broken deps (`devify` used but not declared, `gum` required by a waybar script and absent).

**Recommended path instead of migrating**: continue with the current strategy (GREEN) of cherry-picking sbdots configs/CSS on top of the ML4W plumbing — the best possible use of a frozen repo: the dotfiles (waybar, rofi, swaync, kitty, matugen templates, hyprland.lua as a reference) are the valuable and stable part; the Python framework/installer is the alpha, broken part with no future. If the full stack is still wanted: full backup of `~/.config` first, uninstall ML4W with its own uninstaller, install the package with makepkg by hand and run `sbdots init` (not `install`), accepting that maintenance is on you.

## Status (2026-07-05)

**This is ONLY the audit.** The actual migration — running `install.sh`, `makepkg` or `sbdots init` — **was NOT executed**: no package was installed, no file in `~/.config` or on the system was touched. Everything described above comes from reading the repo code and the GitHub API, not from running anything on this machine. The decision to migrate (or to stay with cherry-picking on top of ML4W, which is the recommendation) is left to the user after reading this document.
