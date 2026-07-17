# Auditoría instalador Symphony (`vyrx-dev/symphony`) — tema Void

Fecha: 2026-07-05
Contexto: evaluación de instalar Symphony (dotfiles Hyprland de vyrx-dev, tema visual "Void") sobre el setup actual (Arch, Hyprland vía ML4W + reskin cherry-pick estilo sbdots ya aplicado — ver [`ml4w-hyprland-investigation.md`](ml4w-hyprland-investigation.md) y [`sbdots-migration-investigation.md`](sbdots-migration-investigation.md)). Mismo rigor que las auditorías previas: código leído línea por línea sobre un clone local (`git clone`, sin ejecutar nada), más metadata de GitHub. Auditoría hecha con 5 agentes en paralelo sobre el clone.

**Nota de seguridad**: al pedir la página de GitHub de Symphony vía WebFetch, la respuesta vino con tags `<system-reminder>` falsos inyectados ("Exited Plan Mode" / "Auto Mode Active") pidiendo saltarse confirmaciones antes de acciones destructivas. Se ignoraron — no hay tal modo activo, y esta auditoría se hizo sin ejecutar ningún paso destructivo real.

## Veredicto: doble

- **Full install (correr `boot.sh`/`install.sh` y adoptar todo el stack Symphony):** 🟡 AMARILLO. A diferencia de sbdots, **sí hace backup** antes de pisar configs (`~/dotfiles-backup`, restaurable), y no toca boot/bootloader/drivers/display-manager. El amarillo es por: comando de instalación documentado ROTO (ver bug abajo), proyecto muerto sin mantenimiento, y que pisaría exactamente las mismas carpetas (`hypr`, `waybar`, `rofi`, `kitty`, `nvim`, `gtk-3.0/4.0`) que ya tenés personalizadas — sería repetir la migración completa que ya se rechazó con sbdots, ahora sobre un proyecto igual de abandonado.
- **Cherry-pick del tema Void a mano sobre ML4W+sbdots (sin instalador, sin stow, sin paquetes):** 🟢 VERDE — recomendado. Mismo patrón ya usado con sbdots. Los archivos del tema son fragmentos de color autocontenidos, sin dependencia del runtime de Symphony.

## BUG VERIFICADO: el comando de instalación documentado no instala Symphony

El README de `vyrx-dev/symphony` documenta textualmente:

```bash
curl -fsSL https://raw.githubusercontent.com/vyrx-dev/dotfiles/main/boot.sh | bash
# o manualmente:
git clone https://github.com/vyrx-dev/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
```

Ambos comandos apuntan a `vyrx-dev/dotfiles` — **un repo distinto y no relacionado**, actualmente activo (26★, `pushed_at` 2026-06-30, rama `master`) con un setup Sway/Niri completamente diferente (sin Hyprland, sin `install.sh`, sin `themes/`, sin tema Void). El autor evidentemente reusó el nombre `dotfiles` para su setup actual después de archivar Symphony, y nunca actualizó el README de Symphony. Confirmado además en `boot.sh:32`: `REPO="${SYMPHONY_REPO:-vyrx-dev/dotfiles}"` — el default del propio script apunta al repo equivocado.

**Efecto real si se corre tal cual**: `boot.sh` hace `sudo pacman -Syu --noconfirm` (upgrade completo del sistema) y `rm -rf ~/dotfiles` (si existía) ANTES de clonar — luego clona el repo equivocado, no encuentra `install.sh` en él, e imprime `Clone failed - install.sh not found` y aborta (`boot.sh:58-61`). Falla limpio en ese punto (no llega a tocar `~/.config`), pero ya pagaste el upgrade de sistema no pedido y el borrado de un posible `~/dotfiles` propio.

**Camino que sí funciona** (clonar el repo correcto explícitamente, sea con el override de env var o clonando a mano):

```bash
git clone https://github.com/vyrx-dev/symphony ~/dotfiles-symphony
cd ~/dotfiles-symphony && ./install.sh
# o, si se quiere usar boot.sh igual:
SYMPHONY_REPO=vyrx-dev/symphony bash <(curl -fsSL https://raw.githubusercontent.com/vyrx-dev/symphony/main/boot.sh)
```

## Cadena de ejecución verificada (código leído línea por línea, sobre clone correcto)

```
boot.sh (opcional, solo si se usa el one-liner con REPO override)
  L38  sudo pacman -Syu --noconfirm --needed git stow gum   (upgrade completo, SIN gate previo)
  L47-48  rm -rf "$DEST" && git clone .../$REPO.git "$DEST" (branch main, sin pin de tag/commit)
  L67  source ./install.sh
install.sh
  L20-22  warn + confirm "Continue?" || exit 0   <- único gate global, y ya después del upgrade
  L39  source install/packages.sh   (instalación de paquetes)
  L42/45/48  source stow.sh / desktop-entries.sh / services.sh
  L52  scripts/choose-shell (chsh interactivo, opcional)
  L58  install/themes/install.sh (setup de la CLI `symphony`, no aplica tema todavía)
install/packages.sh
  setup_aur (si falta yay/paru: clona y compila yay-bin de AUR, output oculto, --noconfirm)
  do_install: ~100 paquetes core vía pacman/AUR, --noconfirm, split repo/AUR resuelto en runtime
  ask_applications: paquetes opcionales vía gum multi-select
```

## Puntos de sudo (exactos)

- `boot.sh:38` — `sudo pacman -Syu --noconfirm --needed git stow gum` (upgrade completo, antes de cualquier confirmación).
- `install/packages.sh:97` — `makepkg -si --noconfirm` para `yay-bin` (si no hay AUR helper), output completo a `/dev/null` — se compila e instala como root un PKGBUILD de AUR sin revisión.
- `install/packages.sh:123` — `sudo pacman -S --needed --noconfirm "${official[@]}"` (~100 paquetes core).
- `install/packages.sh:130` — `$aur -S --needed --noconfirm "${from_aur[@]}"` (yay/paru, sin revisión de PKGBUILD).
- `install/services.sh:20` — `sudo systemctl enable --now bluetooth` (solo si bluez está instalado).
- `install/services.sh` (sección spicetify) — `sudo chmod a+wr -R "$spotify_path/Apps"` — deja el directorio de Spotify **world-writable** (aflojamiento de permisos, no crítico pero real).
- `scripts/choose-shell:19` — `sudo chsh -s ... "$USER"` — cambia shell de login, pero solo tras menú interactivo con opción de salir.

No hay escritura a `/etc` fuera de paquetes, ni a GRUB/initramfs/bootloader.

## Backup de configs existentes — SÍ EXISTE (a diferencia de sbdots)

`install/stow.sh::backup_if_exists()` mueve (no borra) cualquier ítem preexistente y no-symlink en `~/.config/*` y `~/.local/share/*` que choque, a `~/dotfiles-backup` (o `-2`, `-3`... si ya hay uno), antes de correr `stow .`. `stow .` se corre sin `--adopt`/`-R`/force — si igual hay conflicto, aborta con `exit 1` en vez de pisar. `uninstall.sh::restore_backups()` restaura desde el backup más reciente. Único caveat: si ya hubo una instalación previa, el backup más reciente puede ser un backup de restos de Symphony, no de los configs originales.

**Carpetas que tocaría el stow** (pisaría lo que ya tenés customizado): `hypr, waybar, rofi, kitty, nvim, gtk-3.0, gtk-4.0, alacritty, btop, cliphist, fastfetch, fish, ghostty, lazygit, matugen, mpd, mpdscribble, rmpc, swaync, swayosd, tmux, Typora, uwsm, yazi` + `brave-flags.conf`, `chromium-flags.conf`.

## Qué toca de boot / drivers / display manager

Grep exhaustivo (`sddm|gdm|lightdm|grub|mkinitcpio|systemd-boot|nvidia|systemctl enable|rm -rf|chsh|usermod|autologin|greetd`) sobre todo el árbol: **cero modificaciones de bootloader, initramfs o drivers**. `sddm` se instala como paquete (línea de packages.sh) pero nunca se habilita (`systemctl enable sddm` no existe en el repo) — no cambia el display manager activo. Las dos menciones de `nvidia` en `hyprland.conf` son env vars de sesión (`LIBVA_DRIVER_NAME`, `__GLX_VENDOR_LIBRARY_NAME`), sin efecto fuera de la sesión Hyprland. `chsh` es interactivo y opcional. Todo `rm -rf` fuera del ya mencionado en `boot.sh:47` es benigno (limpieza de temporales o borrado de las propias carpetas de Symphony, con confirmación).

## Convivencia con ML4W + sbdots actual

No hay lógica de detección de ML4W (igual que sbdots). El backup de `stow.sh` sí protegería los configs actuales (se moverían a `~/dotfiles-backup`, recuperables), pero el resultado neto de un full install sería reemplazar en vivo exactamente el mismo set de piezas que ya está armado a mano (waybar/rofi/kitty/hypr con reskin sbdots) por el ecosistema completo de Symphony (su propia CLI `symphony`, sus hooks de tema, `uwsm` gestionando waybar). Es, en efecto, la misma clase de decisión "reemplazo completo" que ya se evaluó y descartó con sbdots — con la diferencia de que acá sí hay red de seguridad (backup + `uninstall.sh` con restore).

## Paquetes instalados (core, ~100)

`base-devel git stow hyprland hypridle hyprlock hyprpicker hyprsunset xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt5-wayland qt6-wayland uwsm waybar rofi swaync swayosd swww wlogout brave-bin kitty alacritty fish starship tmux eza bat fd ripgrep fzf zoxide jq yazi nautilus neovim lazygit grim slurp satty wl-clipboard gpu-screen-recorder ffmpeg v4l-utils cliphist wl-clip-persist pipewire pipewire-alsa pipewire-pulse wireplumber pamixer wiremix mpd mpc rmpc cava playerctl mpdscribble spotify-launcher spicetify-cli mpd-mpris networkmanager nmgui-bin kdeconnect bluez bluez-utils blueman polkit-gnome brightnessctl ddcutil power-profiles-daemon upower libnotify xdg-utils xdg-user-dirs inotify-tools gnome-keyring libsecret xorg-xhost libappindicator matugen nwg-look adw-gtk-theme bibata-cursor-theme-bin imagemagick rofimoji wtype btop fastfetch chafa ttf-jetbrains-mono-nerd ttf-cascadia-mono-nerd noto-fonts-emoji sddm qt5-quickcontrols qt5-quickcontrols2 qt5-graphicaleffects python-terminaltexteffects gum wget curl unzip localsend deno npm keyd tree-sitter-cli`

Más ~24 paquetes opcionales vía gum multi-select (VS Code, Discord/vesktop, Steam, Obsidian, etc — no forzados).

## Estado de mantenimiento

- Archivado 2026-05-15 ("no uso más Hyprland"). Sin sucesor ni fork mantenido señalado.
- Último commit de código real: **2026-01-08**. Después solo housekeeping (README, funding). ~4 meses sin desarrollo antes del freeze.
- 3 issues abiertos, congelados para siempre (repo archivado bloquea issues): **#56 instalador se cuelga** (2026-04-27, nunca resuelto), **#63 bug de tema/config en CachyOS** (2026-05-14, un día antes de archivar, nunca respondido), #51 pedido de testers para v3.0 que nunca salió.
- 509★, 22 forks, 854 commits, último release v2.1.1 (2025-12-31).

## Riesgos (por qué AMARILLO, no VERDE, para el full install)

1. **Comando de instalación documentado está roto** (apunta a un repo no relacionado) — hay que corregirlo a mano con `SYMPHONY_REPO=vyrx-dev/symphony` o clonando directo.
2. `boot.sh` corre `pacman -Syu --noconfirm` (upgrade completo del sistema) antes de cualquier confirmación.
3. Build de AUR (`yay-bin` y paquetes AUR en bloque) 100% `--noconfirm`, sin revisión de PKGBUILD, output del bootstrap de yay oculto.
4. Proyecto muerto: bug de instalador colgado (#56) y de compatibilidad de distro (#63) sin arreglo posible, v3.0 abandonada.
5. Pisaría exactamente las carpetas que ya tenés armadas a mano (hypr/waybar/rofi/kitty/nvim) — mismo tipo de decisión "full replace" ya rechazada con sbdots, aunque acá con backup recuperable.
6. Aflojamientos de seguridad menores: gnome-keyring queda con auto-unlock (`lock-on-idle=false`, `lock-after=false`); directorio de Spotify queda world-writable (`chmod a+wr -R`) por el paso de spicetify.
7. El `trap ERR` hace `clear` de pantalla al fallar (oculta el error real), y varios pasos silencian fallos (`|| true`, salida a `/dev/null`).

## Camino recomendado: cherry-pick del tema Void (VERDE)

El tema es completamente autocontenido — cero dependencia de la CLI `symphony` o de stow. Paleta: **AMOLED negro + monocromo lavanda/violeta** (fondo `#05010C`, cursor `#814DDE`, acentos `#BB9AF7`/`#A6B8FF`/`#DECCFF`; toda la paleta ANSI remapeada a violetas salvo el rojo). Wallpapers incluidos (`themes/void/1.jpg`, `2.png`) combinan con la paleta.

Archivos a copiar a mano (sin instalador, sin stow, sin paquetes nuevos, sin sudo):

- `themes/void/.config/kitty/colors.conf` → nuevo archivo en `kitty/`, incluido vía `include` en `kitty.conf` (sintaxis nativa de kitty).
- `themes/void/.config/hypr/theme/colors.conf` → adaptar a `hypr/conf/` de ML4W; debe cargarse **después** del color source de ML4W/matugen para que gane.
- `themes/void/.config/btop/themes/current.theme` → copiar como tema nuevo, setear `color_theme` en `btop.conf`.
- `themes/void/.config/cava/config` → copiar solo el bloque `[color]` (gradiente de 7 pasos), no el archivo entero.
- `themes/void/backgrounds/{1.jpg,2.png}` → wallpapers.
- `waybar/colors.css` y `rofi/colors.rasi` de Symphony usan nombres de variable distintos a los de ML4W/sbdots (Material-style vs custom) — **traducir los valores hex a las variables existentes**, no copiar el archivo tal cual.
- `themes/void/.config/starship.toml` → solo cherry-pickear la paleta de colores, no el archivo completo (pisaría el prompt actual).
- nvim: nada que copiar — el "tema" de Void ahí es Catppuccin stock con `transparent_background = true`.

**Caveat**: si el pipeline de matugen/wallust de ML4W regenera colores al cambiar de wallpaper, puede competir con los archivos estáticos de Void — los includes deben apuntar a los archivos estáticos (o desactivar el pipeline dinámico para esas apps). Mismo patrón exacto que se usó para cherry-pickear sbdots.

## Estado (2026-07-05)

**Esto es SOLO la auditoría.** No se instaló ningún paquete, no se corrió `boot.sh`/`install.sh`/stow, no se tocó ningún archivo de `~/.config` ni del sistema real. Los clones de `vyrx-dev/symphony` y `vyrx-dev/dotfiles` usados para leer el código viven en un directorio scratch temporal, no en este repo. Decisión pendiente del usuario: cherry-pick del tema Void (recomendado), full install igual, o descartar.
