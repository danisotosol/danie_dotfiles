# Rollback ML4W → Symphony

Date: 2026-07-05
Context: before running the Symphony installer (`~/dotfiles-symphony/install.sh`), the ML4W symlinks in `~/.config` were removed so that Symphony's `stow` would not conflict (see [`symphony-migration-investigation.md`](symphony-migration-investigation.md)). The original ML4W data **was not deleted** — it remains intact in `~/.mydotfiles/com.ml4w.dotfiles.stable/.config/`. Unlinking a symlink does not touch the target.

`~/.config/nvim` was NOT touched — it was excluded from Symphony's stow (`^nvim$` added to `~/dotfiles-symphony/.stow-local-ignore`) to keep this repo's LazyVim + AI plugins.

## Removed symlinks (original targets, for restoring)

First batch (before running `install.sh`):

```bash
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/fish ~/.config/fish
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/hypr ~/.config/hypr
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/kitty ~/.config/kitty
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/rofi ~/.config/rofi
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/waybar ~/.config/waybar
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/wlogout ~/.config/wlogout
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/nwg-dock-hyprland ~/.config/nwg-dock-hyprland
```

Second batch (the first `install.sh` run aborted at the stow step because these were also ML4W symlinks and were not in the original list — Claude removed them after diagnosing the conflict):

```bash
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/btop ~/.config/btop
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/chromium-flags.conf ~/.config/chromium-flags.conf
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/fastfetch ~/.config/fastfetch
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/gtk-3.0 ~/.config/gtk-3.0
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/gtk-4.0 ~/.config/gtk-4.0
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/matugen ~/.config/matugen
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/swaync ~/.config/swaync
```

`~/.config/kitty` also had a real directory (not a symlink) recreated in between (probably by the package installation process itself) — `stow.sh` detected it and backed it up on its own, to `~/dotfiles-backup/.config/kitty`. The real `~/.local/share/applications` was also backed up there (`~/dotfiles-backup/.local/share/applications`).

**Current state: Symphony's `stow` has already run and linked everything successfully** — `~/.config/{hypr,waybar,rofi,kitty,fish,btop,fastfetch,gtk-3.0,gtk-4.0,matugen,swaync,...}` now point to `~/dotfiles-symphony/.config/*`. To undo: delete those symlinks (`rm ~/.config/<X>`, destroys nothing in Symphony) and put back the ML4W `ln -sf` commands above (both batches).

## To undo Symphony completely

`~/dotfiles-symphony/uninstall.sh` runs `stow -D .` (removes Symphony's symlinks) and `restore_backups()` (restores from `~/dotfiles-backup*` the most recent backup `stow.sh` made of things that were NOT symlinks — does not apply to fish/hypr/kitty/rofi/waybar/wlogout/nwg-dock-hyprland because those were already symlinks and `backup_if_exists` did not touch them). To go back 100% to ML4W: run `uninstall.sh` and then the `ln -sf` commands above.

## State (2026-07-05, before running install.sh)

ML4W symlinks just removed, `~/.config/nvim` intact. Symphony repo cloned at `~/dotfiles-symphony` (branch `main`, correct — not the broken `vyrx-dev/dotfiles` that the official README documents). `install.sh` **has not been run yet** — it requires sudo and interactive prompts (`gum confirm`, optional apps selector, shell choice), so the user runs it directly in their terminal.
