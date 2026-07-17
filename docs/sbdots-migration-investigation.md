# Auditoría instalador sbdots (`sbalghari/sbdots`) — posible migración desde ML4W

Fecha: 2026-07-05
Contexto: evaluación de abandonar ML4W y migrar el setup Hyprland actual (Arch, Hyprland 0.55.4, ML4W + reskin manual estilo sbdots ya aplicado) al framework completo sbdots corriendo su instalador. sbdots no es una colección de dotfiles para copiar a mano: es un paquete de Arch (PKGBUILD) + CLI Python (Typer) con dos entrypoints (`sbdots` inicializador, `sbdotsctl` control runtime), dos daemons systemd de usuario (`sbdots-actions`, `sbdots-clipboard-listener`), un binario C++ cliente de socket, y dotfiles en `/usr/share/sbdots`. La config de Hyprland es en formato Lua (`hyprland.lua`, API `hl.on`/`hl.exec_cmd`, introducido en Hyprland 0.55 — compatible con el 0.55.4 instalado; `hyprland.lua` tiene precedencia sobre `hyprland.conf`). Theming 100% matugen. Arch-only explícito (`pacman -Qq` y `yay -S` hardcodeados). Licencia GPL-3.0, versión declarada 0.0.3-alpha.

## Veredicto: 🔴 ROJO

ROJO para migración completa (correr el instalador encima del sistema vivo). El rojo NO es por malicia — el código es chico, legible, sin nada turbio: cero tocamientos de boot/drivers/display manager, sudo solo para pacman/yay, services solo user-scope. El rojo es por viabilidad y pérdida de datos: proyecto congelado por admisión propia del autor, instalador verificablemente roto (`sbdots install` no existe), y borrado destructivo de 17 directorios de `~/.config` **sin backup** (comentario literal `# TODO: Add backups` en el código), que destruiría la instalación ML4W viva y también el reskin manual ya hecho. La estrategia actual de cherry-pickear configs/CSS de sbdots sobre la plumbing ML4W sigue siendo VERDE y es el mejor uso posible de un repo congelado.

## Comando / entrypoint

El README **no publica ningún comando de instalación** — solo dice "You could use the install.sh but it isn't fully tested, so use it at your own risk". El script existe en la raíz del repo:

```bash
# equivalente curl|bash, NUNCA documentado por el autor:
curl -fsSL https://raw.githubusercontent.com/sbalghari/sbdots/main/install.sh | bash
```

**BUG VERIFICADO**: el último paso de `install.sh` ejecuta `sbdots install`, pero el CLI Python solo registra el comando `init` (`src/sbdots/__init__.py:47-48`, único `@cli.command()`; el propio mensaje de cancelación del instalador dice "please run 'sbdots init'"). Typer devuelve "No such command 'install'" → `fail "sbdots install failed"` → el bootstrap **aborta después de instalar ~30 paquetes pero antes de tocar ningún dotfile**. El flujo que realmente funciona: correr `install.sh` (o `makepkg` a mano) y después `sbdots init` manualmente.

## Cadena de ejecución verificada (código leído línea por línea)

**Fase 1 — `install.sh` (bash, `set -e`):**

1. `install_system_deps()`: `sudo pacman -S --needed --noconfirm` para git y base-devel si faltan.
2. `install_yay()`: si no hay yay → `rm -rf /tmp/yay`, clone del AUR, `makepkg -si --noconfirm`.
3. `install_aur_deps()`: loop `yay -S --noconfirm` sobre 14 paquetes AUR (lista completa abajo).
4. `download_pkgbuild()`: curl del PKGBUILD a `/tmp/sbdots`.
5. `build()`: `makepkg -si --noconfirm` — clona el repo, construye wheel Python + compila `bin/sbdots-actions.cpp` con g++, e instala vía pacman: CLI en `/usr/bin`, dotfiles en `/usr/share/sbdots`, defaults en `/etc/sbdots`, services en `/usr/lib/systemd/user` (**no** los habilita). Arrastra ~40 depends oficiales.
6. `run_setup()`: `sbdots install` → **ROTO** (el comando es `init`).

**Fase 2 — `sbdots init` (`SBDotsInitializer.install()`):**

- `_validators.py::is_already_installed()`: solo chequea `~/Dotfiles`, `~/Wallpapers`, `~/.sbdots` — si existen, WARN y sigue igual.
- `confirm()` interactivo.
- `ComponentsManager`, 3 pasos:
  - **DotfilesInstaller (crítico)**: valida fuentes en `/usr/share/sbdots/configs` → si existe `~/Dotfiles` **lo borra entero** (`shutil.rmtree`, `dotfiles.py:76-78`) → copia configs a `~/Dotfiles` → verifica → `_remove_existing_configs()`: **borra `~/.config/<X>` para 17 componentes sin backup** (atuin, btop, cava, fastfetch, fish, gtk-3.0, gtk-4.0, hypr, kitty, matugen, neofetch, qt5ct, qt6ct, rofi, swaync, waybar, waypaper, wlogout) → `_create_links()`: symlink `~/Dotfiles/<X>` → `~/.config/<X>`.
  - **WallpapersInstaller (crítico)**: copia wallpapers a `~/Wallpapers` + avatar a `~/.sbdots/.avatar`; opcionalmente clona `github.com/sbalghari/Wallpapers` a `/tmp`.
  - **OptPackagesInstaller (no crítico)**: menú multiselect de 11 paquetes opcionales con `yay -S --noconfirm` bajo `SudoKeepAlive` (thread que refresca `sudo -v` cada 60s, máx 30 min, `sudo -k` al salir).
- `PostInstallHooks`: `systemctl --user daemon-reload` + `systemctl --user start --now` de cada `sbdots-*.service` (solo user scope, solo start, nunca enable — el CHANGELOG confirma el cambio enable→start a propósito); `waypaper --restore`.
- Mensaje final: "Please restart your PC once before using".

**Runtime post-instalación** (`hyprland.lua` al login): `sbdotsctl waybar --start`, hyprpolkitagent, swaync, los 2 daemons sbdots, wl-paste, udiskie, `devify` (AUR, **no está en deps — falla silenciosa**), `waypaper --restore`.

## Puntos de sudo (exactos)

Instalador:

- `install.sh:49` — `sudo pacman -S --needed --noconfirm "$dep"` (git, base-devel).
- `install.sh:69` y `:105` — `makepkg -si --noconfirm` (×2: yay y sbdots-git; makepkg invoca sudo pacman internamente).
- `install.sh:79` — `yay -S --noconfirm <pkg>` (×14 AUR; yay eleva con sudo internamente).
- `src/sbdots/library/sudo_keep_alive.py:33` `sudo -v`, `:61` `sudo -v` en loop cada 60s (thread daemon, máx 30 min), `:82` `sudo -k` — solo envuelve la instalación de paquetes opcionales (`packages.py:63`).
- `src/sbdots/library/pkg_utils.py:23` — `yay -S <pkg> --noconfirm --quiet` (opcionales).

Runtime (disparados por el usuario después):

- `src/sbdots/ctl/updates.py:72` — `sudo pacman -Syu --noconfirm`, más `yay/paru -Syu --noconfirm`, `pacman -Rns <huérfanos> --noconfirm`, `pacman -Sc --noconfirm` y `reboot`, vía `run_sudo_cmd` (`commands.py:123`: wrapper pexpect que detecta el prompt de sudo e inyecta la contraseña pedida por el CLI; desactiva el logfile durante el password, pero loguea el output a `/tmp/sudo_output.log` — path predecible en /tmp, leak menor).
- `dotfiles/configs/waybar/scripts/installupdates.sh:47` — `sudo pacman -Syu --noconfirm`; `:59` — `sudo pacman -Rns $(pacman -Qdtq) --noconfirm` (limpieza de huérfanos sin confirmación: riesgosa en un sistema con restos de ML4W).

**No hay**: sudo a archivos de sistema fuera de pacman, ediciones de `/etc` (solo el PKGBUILD instala `/etc/sbdots/rich_theme.toml` como parte del paquete), ni escrituras privilegiadas arbitrarias.

## Qué toca de boot / drivers / display manager

Grep exhaustivo sobre todo el árbol (`*.py`, `*.sh`, `*.service`, PKGBUILD, `*.toml`, `*.conf`, `*.lua`) por `sddm|gdm|grub|mkinitcpio|systemd-boot|nvidia|lightdm|systemctl|dd|rm -rf`: **cero modificaciones de boot, bootloader, initramfs, drivers o display manager**.

- `sddm`: único hit en `src/sbdots/constants.py:103` — string dentro de `OPTIONAL_PACKAGES`; si el usuario lo marca se **instala** el paquete, pero nunca se ejecuta `systemctl enable sddm` (no existe ningún `systemctl enable` en el repo; el CHANGELOG registra el fix "use start instead of enable").
- `systemctl`: solo scope `--user` (`postinstall/start_service.py:36,64`; `hypr/hyprland.lua:32-35`; `hypridle.conf:25` con `systemctl suspend` on-timeout — comando estándar de idle).
- `nvidia`: solo valor cosmético en `btop.conf:267-268`.
- `rm -rf`: solo `install.sh:64,73` sobre `/tmp/yay`.
- `gdm|grub|mkinitcpio|systemd-boot|lightdm|dd`: cero hits.
- Los dos `.service` son unidades de **usuario** en `/usr/lib/systemd/user`, `WantedBy=default.target`, sin privilegios (el cliplistener incluso con `NoNewPrivileges=true` y `PrivateTmp=true`).
- Tampoco hay `chsh`/`usermod`/autologin/greetd/xinitrc (grep aparte: cero hits) — instala fish pero no lo setea como shell por defecto.

## Backup de configs existentes

**NO EXISTE.** Confirmado en código: `dotfiles.py:115` tiene el comentario literal `# TODO: Add backups` justo arriba de `_remove_existing_configs()`, que hace `shutil.rmtree`/unlink de `~/.config/<componente>` para los 17 componentes (incluye `hypr`, `waybar`, `kitty`, `rofi`, `swaync`, `wlogout`, `gtk-3.0`, `gtk-4.0`, `qt5ct`, `qt6ct`, `fish`…). Además `dotfiles.py:76-78` borra `~/Dotfiles` entero si ya existe. Daño colateral: borrar `gtk-3.0` se lleva `~/.config/gtk-3.0/bookmarks` (marcadores del file manager). No hay comando uninstall, no hay restore, no hay backup con timestamp como sí hace ML4W (`~/.ml4w-backup`). Si `sbdots init` falla a mitad de camino (después de borrar, antes de symlinkear), el usuario queda sin configs de Hyprland/waybar y la próxima sesión arranca rota, sin rollback automático.

## Convivencia con el ML4W actual

**No puede convivir y no migra**: sbdots ignora por completo la existencia de ML4W. El único chequeo previo busca instalaciones viejas de SBDots, y aun encontrándolas solo warnea y sigue. Corriéndolo encima del sistema actual:

1. **Paquetes**: no desinstala nada de ML4W; instala ~55 paquetes propios encima. Solapamiento grande (waybar, rofi, swaync, kitty, hyprlock, hypridle ya están). Conflicto probable: `qt6ct-kde`/`qt5ct-kde` (AUR) contra `qt6ct`/`qt5ct` vanilla de ML4W — con `yay --noconfirm` puede abortar el install.sh a mitad de la fase de paquetes. Suma segundo icon theme (tela-circle + breeze), segundo cursor (bibata), fish+starship, y `awww` como daemon de wallpaper conviviendo con el de ML4W (no arrancan a la vez, pero quedan instalados).
2. **Configs**: `sbdots init` borra sin backup `~/.config/hypr`, waybar, rofi, swaync, wlogout, kitty y 11 más — destruye la instalación ML4W viva **y también el reskin manual ya hecho** (los CSS tuneados de waybar/rofi/swaync/wlogout/kitty viven exactamente en esas carpetas). ML4W queda decapitado pero no removido: sobreviven `~/.ml4w*`, las apps ML4W (settings, welcome, sidebar), sus paquetes y su caché — y son una trampa: cualquier utilidad ML4W de "restore/update" ejecutada después intentará reescribir `~/.config` pisando los symlinks de sbdots.
3. **Sesión**: no toca SDDM ni la sesión — se sigue entrando por el login actual; Hyprland 0.55.4 encuentra `hyprland.lua` (precedencia sobre `.conf`) y carga el mundo sbdots completo: keybinds distintos, `sbdotsctl` gestionando waybar, matugen en vez del theme engine ML4W. No hay "dos waybars" en runtime porque el reemplazo es total, pero sí dos ecosistemas instalados a nivel paquetes.
4. **El camino real**: como install.sh se rompe en `sbdots install`, el escenario más probable hoy es: instala ~30-55 paquetes, aborta, y no toca ni un config — migración a medias que hay que terminar a mano con `sbdots init`, asumiendo todos los riesgos de borrado sin backup. Una migración limpia exigiría: backup manual completo de `~/.config`, desinstalar ML4W con su propio uninstaller primero, y recién ahí sbdots — nada de eso lo hace el instalador.

## Paquetes instalados

**install.sh vía yay (14, AUR)**: nautilus, nautilus-code, nautilus-copy-path, nautilus-hide, matugen-bin, python-inquirerpy (vestigial — cero imports en `src/`), qt6ct-kde, qt5ct-kde (conflicto potencial con qt6ct/qt5ct de ML4W), hyprshade, bibata-cursor-theme-bin, aur-check-updates, waypaper, wlogout, neofetch (upstream archivado).

**PKGBUILD depends (~40, repos oficiales — awww/uwsm/tela/hyprpolkitagent verificados contra archlinux.org)**: atuin, power-profiles-daemon, hyprpolkitagent, breeze-icons, breeze-gtk, awww, blueman, brightnessctl, btop, eza, fastfetch, figlet, fish, gnome-keyring, hypridle, hyprlock, hyprpicker, hyprshot, kitty, kwalletmanager, noto-fonts, pacman-contrib, pavucontrol, polkit-kde-agent, python-pexpect, python-psutil, python-pyfiglet, python-requests, python-rich, python-setproctitle, python-typer, rofi, starship, swaync, tela-circle-icon-theme-standard, ttf-dejavu, ttf-jetbrains-mono(+nerd), udiskie, uwsm, waybar, wl-clipboard. makedepends: git, python-build/installer/wheel/setuptools, gcc.

**Opcionales a elección (11)**: visual-studio-code-bin, vlc, smile, sddm, obs-studio, mission-center, freedownloadmanager-bin, loupe, libreoffice-fresh, gnome-text-editor, ark.

**No desinstala nada**: cero `pacman -R` en el instalador (el único `-Rns` es la limpieza de huérfanos en las herramientas de update runtime, peligrosa post-migración porque los deps huérfanos de ML4W caerían ahí). Deps rotas detectadas: `devify` (hyprland.lua lo ejecuta al arrancar, no declarado — falla silenciosa) y `gum` (`installupdates.sh` lo requiere y sale con error si falta; no está en depends).

## Estado de mantenimiento

Confirmado con evidencia fresca (API de GitHub, consultada hoy 2026-07-05): el repo **no está archivado** (`archived: false`, `disabled: false`), pero el desarrollo está **detenido por declaración explícita del autor** en el README de `main` (texto literal): *"[!WARNING] Further Development is stopped at the moment. You could use the install.sh but it isn't fully tested, so use it at your own risk."*

- Último push: 2026-06-18 18:18 UTC — y es precisamente "Update README.md", el commit donde presumiblemente anuncia el freeze.
- Último trabajo real de código: 2026-06-08 ("merge branch dev into main", "style: improve waybar and swaync look"). ~4 semanas sin actividad; freeze anunciado hace ~2.5 semanas.
- Issues abiertos: 0. Proyecto chico: 83 stars, 4 forks, un solo mantenedor (Saifullah Balghari).
- Los últimos issues/PRs (#20-#27, mayo-junio 2026) muestran una refactor grande a medio asentar (migración a Lua, a systemd services, a matugen), rematada con commits "fix incomplete/incorrect stuff introduced by previous refactors". El freeze agarró al proyecto recién salido de esa reestructuración, y el bug `sbdots install` vs `init` quedó sin arreglar.
- Versión: 0.0.3-alpha en `pyproject.toml` (0.1.0 en CHANGELOG, 2026-06-01) — alpha por admisión propia.

## Riesgos (por qué ROJO)

1. **Proyecto muerto por admisión propia**: freeze declarado en el README, último código real 2026-06-08, un solo mantenedor. Migrar el daily driver a un framework con daemons propios, CLI propio y formato Lua de Hyprland 0.55 recién estrenado, sin nadie que arregle breakages futuros de Hyprland/waybar, es adoptar deuda sin soporte.
2. **Instalador verificablemente roto**: `install.sh` termina en `sbdots install`, comando inexistente (el CLI solo registra `init`). Corrido tal cual: instala ~30-55 paquetes y aborta. El propio README avisa "isn't fully tested, use at your own risk".
3. **Borrado destructivo sin backup**: `sbdots init` hace rmtree de 17 directorios de `~/.config` y de `~/Dotfiles` entero, con un `# TODO: Add backups` literal en el código. Destruye la instalación ML4W viva y el reskin manual ya hecho. Si falla a mitad, la próxima sesión arranca rota sin rollback. ML4W al menos respalda antes de pisar; esto no.
4. **Cero conciencia de migración**: no detecta ni limpia ML4W. Quedarían `~/.ml4w*`, apps y paquetes ML4W huérfanos, con la trampa de que cualquier herramienta ML4W ejecutada después pisaría los symlinks de sbdots; y las herramientas de update de sbdots hacen `pacman -Rns $(pacman -Qdtq) --noconfirm`, que post-migración podría llevarse deps huérfanas de ML4W sin preguntar.
5. **Conflictos de paquetes probables**: `qt6ct-kde`/`qt5ct-kde` (AUR) vs `qt6ct`/`qt5ct` de ML4W pueden abortar el install.sh con `--noconfirm`; deps rotas menores (`devify` usado pero no declarado, `gum` requerido por script de waybar y ausente).

**Camino recomendado en vez de migrar**: seguir con la estrategia actual (VERDE) de cherry-pickear configs/CSS de sbdots sobre la plumbing ML4W — el mejor uso posible de un repo congelado: los dotfiles (waybar, rofi, swaync, kitty, matugen templates, hyprland.lua como referencia) son la parte valiosa y estable; el framework Python/instalador es la parte alpha, rota y sin futuro. Si igual se quisiera el stack completo: backup total de `~/.config` primero, desinstalar ML4W con su propio uninstaller, instalar el paquete con makepkg a mano y correr `sbdots init` (no `install`), sabiendo que el mantenimiento queda en manos propias.

## Estado (2026-07-05)

**Esto es SOLO la auditoría.** La migración real — correr `install.sh`, `makepkg` o `sbdots init` — **NO se ejecutó**: no se instaló ningún paquete, no se tocó ningún archivo de `~/.config` ni del sistema. Todo lo descrito arriba sale de leer el código del repo y de la API de GitHub, no de ejecutar nada en esta máquina. La decisión de migrar (o de quedarse con el cherry-picking sobre ML4W, que es lo recomendado) queda pendiente del usuario tras leer este documento.
