# Rollback ML4W → Symphony

Fecha: 2026-07-05
Contexto: antes de correr el installer de Symphony (`~/dotfiles-symphony/install.sh`), se sacaron los symlinks de ML4W en `~/.config` para que el `stow` de Symphony no chocara (ver [`symphony-migration-investigation.md`](symphony-migration-investigation.md)). Los datos originales de ML4W **no se borraron** — siguen intactos en `~/.mydotfiles/com.ml4w.dotfiles.stable/.config/`. Unlinkear un symlink no toca el destino.

`~/.config/nvim` NO se tocó — se excluyó del stow de Symphony (`^nvim$` agregado a `~/dotfiles-symphony/.stow-local-ignore`) para conservar el LazyVim + plugins IA de este repo.

## Symlinks removidos (targets originales, para restaurar)

Primera tanda (antes de correr `install.sh`):

```bash
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/fish ~/.config/fish
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/hypr ~/.config/hypr
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/kitty ~/.config/kitty
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/rofi ~/.config/rofi
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/waybar ~/.config/waybar
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/wlogout ~/.config/wlogout
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/nwg-dock-hyprland ~/.config/nwg-dock-hyprland
```

Segunda tanda (el primer `install.sh` abortó en el paso de stow porque estos también eran symlinks ML4W y no estaban en la lista original — los sacó Claude después de diagnosticar el conflicto):

```bash
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/btop ~/.config/btop
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/chromium-flags.conf ~/.config/chromium-flags.conf
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/fastfetch ~/.config/fastfetch
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/gtk-3.0 ~/.config/gtk-3.0
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/gtk-4.0 ~/.config/gtk-4.0
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/matugen ~/.config/matugen
ln -sf ../.mydotfiles/com.ml4w.dotfiles.stable/.config/swaync ~/.config/swaync
```

`~/.config/kitty` además tenía un directorio real (no symlink) recreado entre medio (probablemente por el propio proceso de instalación de paquetes) — `stow.sh` lo detectó y lo backupeó solo, en `~/dotfiles-backup/.config/kitty`. `~/.local/share/applications` real también se backupeó ahí (`~/dotfiles-backup/.local/share/applications`).

**Estado actual: el `stow` de Symphony ya corrió y linkeó todo exitosamente** — `~/.config/{hypr,waybar,rofi,kitty,fish,btop,fastfetch,gtk-3.0,gtk-4.0,matugen,swaync,...}` ya apuntan a `~/dotfiles-symphony/.config/*`. Para deshacer: borrar esos symlinks (`rm ~/.config/<X>`, no destruye nada de Symphony) y reponer los `ln -sf` de ML4W de arriba (ambas tandas).

## Para deshacer Symphony del todo

`~/dotfiles-symphony/uninstall.sh` corre `stow -D .` (saca los symlinks de Symphony) y `restore_backups()` (restaura desde `~/dotfiles-backup*` el backup más reciente que haya hecho `stow.sh` de cosas que NO eran symlinks — no aplica a fish/hypr/kitty/rofi/waybar/wlogout/nwg-dock-hyprland porque esos ya eran symlinks y `backup_if_exists` no los tocó). Para volver 100% a ML4W: correr `uninstall.sh` y después los `ln -sf` de arriba.

## Estado (2026-07-05, antes de ejecutar install.sh)

Symlinks de ML4W recién removidos, `~/.config/nvim` intacto. Repo Symphony clonado en `~/dotfiles-symphony` (rama `main`, correcto — no el `vyrx-dev/dotfiles` roto que documenta el README oficial). `install.sh` **todavía no se ejecutó** — requiere sudo y prompts interactivos (`gum confirm`, selector de apps opcionales, elección de shell), así que lo corre el usuario directamente en su terminal.
