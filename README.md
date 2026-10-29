# danie_dotfiles

Personal configs for an Arch Linux laptop running Hyprland. The desktop itself
(Hyprland, theming, scripts) comes from a [Symphony](https://github.com/vyrx-dev/symphony)
checkout at `~/dotfiles-symphony`, installed with stow. This repo holds what sits on top of it.

## Desktop stack

- **Session:** Hyprland under uwsm, picked in SDDM. KDE Plasma stays installed as a separate session.
- **Configs:** Symphony (`~/dotfiles-symphony`, local commits on top of upstream, never pushed).
  ML4W was rolled back; its data is still in `~/.mydotfiles` (see [`docs/symphony-rollback.md`](docs/symphony-rollback.md)).
- **Bar and dock:** MacShell (Quickshell, `~/.local/share/macshell`), patched with the files in `macshell/`. Waybar is disabled.

## Layout

| Path | What it is | Installed by |
|---|---|---|
| `nvim/` | LazyVim config, based on [Gentleman.Dots](https://github.com/Gentleman-Programming/Gentleman.Dots) | `make link-nvim` → `~/.config/nvim` |
| `kitty/kitty.conf` | kitty config (stale, see [Known issues](#known-issues)) | `make link-kitty` |
| `git/config` | shared git settings: delta pager, zdiff3 conflicts, aliases | `make link-git` adds an `include.path` to `~/.gitconfig` |
| `claude/statusline.sh` | Claude Code status line; also caches the plan's rate limits for the MacShell widget | referenced by path from `~/.claude/settings.json` |
| `claude/skills/`, `claude/agents/` | Claude Code skills and the `blind-reviewer` agent; third-party skills keep their own `LICENSE` | `make link-claude` → `~/.claude/skills/`, `~/.claude/agents/` |
| `macshell/` | MacShell bar patches (RAM widget, hide empty workspaces, Claude usage widget) and the widget's data feed | by hand, see below |
| `docs/` | notes from the July 2026 desktop migration (historical) | — |
| `CLAUDE.md` | instructions for Claude Code in this repo (project memory through `memory-rag`) | — |

## Install on a new machine

```bash
git clone <this-repo-url> ~/Documents/danie_dotfiles
make -C ~/Documents/danie_dotfiles link
nvim --headless "+Lazy! restore" +qa
```

`make link` only creates symlinks. A target that exists and is not already a symlink is left
alone and reported as `skip:`.

Then, by hand:

1. **Claude Code status line**, in `~/.claude/settings.json`:
   ```json
   "statusLine": { "type": "command", "command": "~/Documents/danie_dotfiles/claude/statusline.sh" }
   ```
2. **MacShell patches**, in this order:
   ```bash
   cd ~/.local/share/macshell/MacShell
   for p in ram-widget workspaces-occupied claude-widget; do
     patch -p1 < ~/Documents/danie_dotfiles/macshell/$p.patch
   done
   ```
   Then add `"ram"` and `"claude"` to `barWidgets` in `~/.config/macbar/settings.json`.
   The Claude widget reads `claude-usage.py` and the logo from `~/Documents/danie_dotfiles/macshell`
   (hardcoded). A MacShell update may overwrite `MacBar.qml`; re-apply the patches afterwards.

## Known issues

- `kitty/kitty.conf` is stale. The live `~/.config/kitty/kitty.conf` is a real file managed by
  Symphony (it includes `~/.config/symphony/current/.config/kitty/colors.conf`), so
  `make link-kitty` skips it.
