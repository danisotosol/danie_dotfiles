# Investigación ML4W Dotfiles (Hyprland) — convivencia con KDE Plasma

Fecha: 2026-07-05
Contexto: instalación de Hyprland vía proyecto ML4W (`mylinuxforwork/dotfiles`) en Arch Linux, con KDE Plasma ya instalado. Objetivo: que convivan en paralelo sin romper Plasma. Se descartaron antes HyDE y JaKooLit por modificar GRUB/SDDM/drivers NVIDIA.

## Veredicto: AMARILLO

Seguro instalar junto a Plasma. No toca GRUB, systemd-boot, mkinitcpio, drivers NVIDIA, SDDM ni GDM. Sí reemplaza dotfiles de usuario (`.bashrc`, `.zshrc`, temas GTK/Qt) con backup automático previo, y encadena un par de scripts remotos no pinneados a una versión fija.

## Comando ejecutado

```bash
bash <(curl -s https://ml4w.com/os/stable)
```

Este comando sirve un script bash real (no landing page) de 68 líneas.

## Cadena de ejecución verificada (código leído línea por línea)

1. `https://ml4w.com/os/stable` → bootstrap script.
2. Clona `mylinuxforwork/ml4w-dotfiles-installer` **pinneado al tag `0.2.5`**, corre `make install` (copia solo a `~/.local/bin` y `~/.local/share`, sin sudo — Makefile verificado).
3. Ejecuta:
   ```bash
   ml4w-dotfiles-installer --install https://raw.githubusercontent.com/mylinuxforwork/dotfiles/main/hyprland-dotfiles-stable.dotinst
   ```
4. El `.dotinst` (JSON) apunta a `mylinuxforwork/dotfiles` rama `main` (sin tag), subcarpeta `dotfiles/`. El instalador corre en orden:
   - `setup/preflight-arch.sh`
   - instala listas de paquetes (`setup/dependencies/packages`, `packages-arch`)
   - `setup/post-arch.sh`
   - crea symlinks de dotfiles (con backup previo)
   - `setup/migration.sh`

## Puntos de sudo (exactos)

- Bootstrap: `sudo pacman -S --needed --noconfirm git make curl jq`
- `lib/helpers.sh` (si falta `gum`): `sudo pacman -S --needed --noconfirm gum`
- `setup/preflight-arch.sh`: `sudo pacman --noconfirm -S "base-devel"`, y si tenés `swww` instalado: `sudo pacman -Rns --noconfirm swww` (se reemplaza por `awww`)
- `setup/_fonts.sh`: `sudo cp -rf .../setup/fonts/* /usr/share/fonts` — única escritura a directorio de sistema en el path Arch
- Instalación de paquetes AUR: `yay/paru -S --needed --noconfirm` (sin sudo) o `sudo pacman -S --needed --noconfirm` como fallback

Todo con `--noconfirm`, pero hay un gate humano antes de arrancar: `gum confirm "Do you want to proceed with the installation?"` con ficha completa del perfil (nombre, id, versión, fuente).

## Backup de configs existentes

Antes de crear cada symlink (`lib/utils.sh::create_symlink`):

```bash
if [ -e "$target" ]; then
    warn "  - Existing file/folder found at $target. Creating backup..."
    mkdir -p "$backup_dir"
    cp -a "$target" "$backup_dir/"
    rm -rf "$target"
fi
ln -s --relative "$source" "$target"
```

Backups quedan en `~/.mydotfiles/backups/<perfil>/<timestamp>/`. El original se borra tras copiarlo — recuperable solo desde ese backup.

## Qué NO toca (por qué no es ROJO)

Grep exhaustivo (`sddm|gdm|grub|mkinitcpio|systemd-boot|nvidia|lightdm|systemctl`) sobre `mylinuxforwork/dotfiles` y `ml4w-dotfiles-installer` completos: **cero hits en el path de Arch**. Único hit relacionado: `sddm-qt6` en `packages-opensuse` (solo openSUSE). No hay ningún `systemctl enable` en ningún script del path Arch. La sesión "Hyprland" en SDDM aparece porque el paquete oficial `hyprland` de Arch trae `/usr/share/wayland-sessions/hyprland.desktop` — sesión adicional estándar; la de Plasma queda intacta.

## Paquetes instalados

Comunes: wget, curl, git, rsync, unzip, tar, jq, flatpak, vim, inotify-tools, udisks2, gvfs, udiskie, hyprpaper, hyprlock, hypridle, hyprpicker, xdg-desktop-portal-hyprland, kitty, vlc, nwg-dock-hyprland, waybar, rofi, nwg-look, pavucontrol, neovim, blueman, qt6ct, nautilus, gnome-text-editor, firefox, xdg-user-dirs, xdg-desktop-portal-gtk, figlet, fastfetch, htop, xclip, zsh, fzf, brightnessctl, tumbler, slurp, cliphist, grim, breeze, tesseract, wl-clipboard, btop, cargo, eza, libsecret.

Arch: hyprland, hyprsysteminfo, hyprshutdown, libnotify, qt5-wayland, qt6-wayland, gnome-themes-extra, uwsm, python-pip, python-gobject, python-screeninfo, nm-connection-editor, network-manager-applet, imagemagick, polkit-gnome, hyprsunset, grimblast-git, pacman-contrib, loupe, power-profiles-daemon, swaync, python-pywalfox, tesseract-data-eng, otf-font-awesome, ttf-firacode-nerd, ttf-jetbrains-mono-nerd, qt6-svg, qt6-virtualkeyboard, qt6-multimedia-ffmpeg, gvfs-mtp, quickshell, awww, matugen, nwg-displays.

## Riesgos / cosas a vigilar (por qué AMARILLO y no VERDE)

1. Reemplaza `~/.bashrc` y `~/.zshrc` por symlinks a versiones ML4W (con backup previo). Si hay customizaciones de shell, mergear manualmente después desde el backup.
2. Symlinkea en `~/.config`: gtk-3.0, gtk-4.0, `.gtkrc-2.0`, qt6ct, xsettingsd, kitty, rofi, waybar, btop, fastfetch, fish, vim, etc. No toca nada de Plasma (`kdeglobals`, `kwinrc`, `plasma*`), pero cambia el theming GTK/Qt de apps GTK dentro de la sesión Plasma actual. Cosmético y reversible desde el backup.
3. Scripts remotos no pinneados a versión: `post-arch.sh` corre `curl -s https://ohmyposh.dev/install.sh | bash` y `bash <(curl -s .../ml4w-dotfiles-settings/main/setup.sh)` (este último solo instala a `~/.local/bin`, sin sudo). Los dotfiles en sí se clonan de `main`, no de un tag — lo auditado hoy puede diferir levemente de lo que se ejecute en el futuro.
4. Desinstala `swww` si estaba, e instala `yay` o `paru` si no había AUR helper.

## Estado tras ejecución (2026-07-05)

El usuario corrió el comando en su máquina real; la salida final fue `success "Setup process finished!"` — línea final del bootstrap (`set -e` implica que si algo hubiera fallado antes, no habría llegado a imprimirse). Instalación completada correctamente.

### Siguientes pasos pendientes
- Reiniciar el sistema.
- En SDDM elegir sesión "Hyprland" para probar (la de Plasma sigue disponible).
- Revisar `~/.mydotfiles/backups/<perfil>/<timestamp>/` si algo de shell/theming quedó distinto a lo esperado.
