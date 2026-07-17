# danie_dotfiles

Configs personales, symlinkeadas desde `~/.config/`.

## Estado actual (2026-07-05)

- **Entorno de escritorio:** KDE Plasma sigue instalado (intacto, disponible como sesión separada). **Sesión activa ahora: Hyprland** (ya reiniciado y elegido en SDDM, corriendo en vivo).
- **Hyprland:** instalado vía ML4W (`bash <(curl -s https://ml4w.com/os/stable)`), tag del installer `0.2.5`, dotfiles de ML4W en rama `main`. Wallpaper activo: Serial Experiments Lain (paleta dinámica matugen, tonos rojo/salmón).
  - Detalle completo de la investigación de instalación (qué toca, qué no, puntos de sudo, backups, paquetes instalados, riesgos) en [`docs/ml4w-hyprland-investigation.md`](docs/ml4w-hyprland-investigation.md).
  - ML4W hizo backup automático de configs previas en `~/.mydotfiles/backups/<perfil>/<timestamp>/` antes de symlinkear `.bashrc`, `.zshrc`, temas GTK/Qt, etc.
- **Reskin estético (sbalghari/sbdots, cherry-pick sobre ML4W, decisión vigente):** se portaron piezas visuales sueltas de sbdots (CSS/config) SIN tocar la plumbing de ML4W — waybar (tema nuevo `sbdots-modern`), rofi (`config.rasi` editado), swaync y wlogout (temas nuevos `sbdots-modern`), kitty (`custom.conf`), blur global en `hypr/conf/decorations/default.lua`, y Firefox con estética "Lain" (`userChrome.css` + `user.js` en el perfil activo; Pywalfox ya instalado por el usuario).
  - **Se evaluó y se DESCARTÓ migrar completamente a sbdots** (reemplazar ML4W por el instalador propio de sbdots). Veredicto 🔴 ROJO: instalador verificablemente roto (`sbdots install` no existe), borra 17 carpetas de `~/.config` sin backup, proyecto congelado por el propio autor. Auditoría completa en [`docs/sbdots-migration-investigation.md`](docs/sbdots-migration-investigation.md). **Decisión: seguir con cherry-pick, no migrar.**
- **Fix de atajos post-cambio Plasma→Hyprland:** se agregó `CTRL+Q` → cerrar ventana activa (mismo script que `SUPER+Q`) en `hypr/conf/keybindings/default.lua`, y right-click en la taskbar de waybar (`wlr/taskbar`) se cambió de `close` a `minimize` (cerraba Firefox completo si era la única ventana).
- **Este repo (`danie_dotfiles`):** inicializado localmente (`git init`), con `kitty/`, `nvim/`, `README.md`, `.gitignore`, y `docs/`. **Sin commits todavía** (a propósito, por pedido explícito — no commitear hasta indicación) — todo aparece como *untracked* en `git status`.

## Pendiente (para retomar en la próxima sesión)

- **Win+Q sigue sin confirmar 100%.** El script `killactive.sh` tiene un `notify-send` de debug al inicio (temporal, para diagnóstico) — SACARLO una vez confirmado. `hyprctl binds` muestra el bind bien registrado (igual que `CTRL+Q`, que sí funciona), pero no quedó confirmado limpio si `SUPER+Q` cierra ventana en una prueba fresca (sin reusar una ventana ya cerrada por otra tecla antes). Repetir el test: ventana nueva, un solo intento de Win+Q, confirmar si cierra.
- **Integración de [hakuimaku/hakuspace](https://github.com/hakuimaku/hakuspace) como capa complementaria (no reemplaza sbdots) — se lanzó un workflow pero no se pudo confirmar su finalización** (no llegó notificación, el task ID no aparece en `TaskList`/`TaskOutput`). Falta revisar si corrió, y si hizo falta, relanzarlo.
- Reload pendiente para que se vean los cambios de reskin: `hyprctl reload`, reload de waybar (`SUPER+SHIFT+B`), `swaync-client -R && swaync-client -rw`, reiniciar Firefox y kitty, y cambiar el wallpaper una vez para regenerar templates de matugen nuevos (Firefox/wlogout).

## Contenido

- `kitty/kitty.conf` → symlink desde `~/.config/kitty/kitty.conf`
  - Cursor trail animado, transparencia (`background_opacity 0.85`), fuente `MesloLGS NF`, remote control habilitado.
- `nvim/` → symlink desde `~/.config/nvim`
  - Basado en [Gentleman.Dots](https://github.com/Gentleman-Programming/Gentleman.Dots) (LazyVim + plugins de IA: avante, claude-code, copilot, gemini, code-companion; + obsidian, oil, smear, etc).
  - Fix aplicado en `lua/config/lazy.lua`: el import `lazyvim.plugins.extras.lang.typescript.biome` no existe en LazyVim — se separó en `lang.typescript` + `formatting.biome` (dos extras reales).

## Instalar en una maquina nueva

```bash
git clone <url-de-este-repo> ~/Documents/danie_dotfiles
ln -sf ~/Documents/danie_dotfiles/kitty/kitty.conf ~/.config/kitty/kitty.conf
ln -sf ~/Documents/danie_dotfiles/nvim ~/.config/nvim
nvim --headless "+Lazy! restore" +qa
```
