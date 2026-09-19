---
name: hyprland-customize
description: Customize this Hyprland + Quickshell dotfiles fork (hyprland lua config, quickshell QML widgets, keybinds, themes). Use when the user says customize hyprland, change keybinds, tweak the bar, add widgets, or asks about dots-hyprland, quickshell, or their hypr setup.
---

# Hyprland Customize

This repo is a fork of `end-4/dots-hyprland` (illogical-impulse). Read `FORK.md`
in the repo root first — it documents remotes, branches, and workflows.

## Fork rules (never break these)

- Remotes: `origin` = our fork (SSH), `upstream` = `end-4/dots-hyprland` mainline.
- Work on branch `custom`. NEVER commit to `main` — it stays a pristine
  mirror of upstream for easy rebasing.
- Prefix custom commits with `custom:`, e.g. `custom: add network speed to bar`.
- Never commit personal identity (real name, email, key comments) to any file.
  Commits use the repo-local noreply identity.
- New machines clone with `git clone -b custom <fork-url>` then
  `git remote add upstream https://github.com/end-4/dots-hyprland.git`.

## Layout

- `dots/.config/hypr/hyprland/*.lua` — Hyprland config (luaified):
  `general.lua`, `keybinds.lua`, `variables.lua`, `rules.lua`, `execs.lua`,
  `env.lua`, plus `scripts/` and `lib/`.
- `dots/.config/quickshell/ii/` — Quickshell shell (QML): `shell.qml` entry,
  `services/` (e.g. `ResourceUsage.qml` polled system stats),
  `modules/ii/bar/`, `modules/ii/verticalBar/`, `modules/common/Config.qml`
  (user options), `modules/common/widgets/` (shared components).
- `sdata/` — install/update scripts (`./setup install`, `./setup exp-update`).

## Prefer update-friendly overrides for Hyprland settings

Upstream supports `~/.config/hypr/custom/variables.lua` — `variables.lua` says
"Copy these to `~/.config/hypr/custom/variables.lua` to make changes in a
dotfiles-update-friendly manner", and `keybinds.lua` / `execs.lua` check that
`custom/` dir. Use it for app choices, variables, and personal scripts instead
of editing repo lua files when possible. Quickshell QML widgets have no such
override — those require repo edits on `custom`.

## Deploying changes (repo edits do NOTHING until deployed)

The live config is a COPY at `~/.config/quickshell/ii` (and `~/.config/hypr/`),
not a symlink. After editing repo files:

```bash
REPO=~/dots-hyprland/dots/.config/quickshell/ii; DEST=~/.config/quickshell/ii
cp -f "$REPO/<changed-file>" "$DEST/<changed-file>"   # per changed file
```

Then reload:

- Quickshell: restart it —
  `setsid qs -c ii -d </dev/null >/tmp/qs-restart.log 2>&1 < /dev/null & disown`
  (Do NOT use `kill -USR1`: it reloads then drops the process. Do NOT use
  bare `pkill -f "qs -c ii"`: the pattern matches your own shell — anchor as
  `^qs` if you must pkill.)
- Hyprland config: `hyprctl reload`.

## Verifying

- `pgrep -x qs` — shell must be running after any restart.
- `grep -i error /tmp/qs-restart.log` — must be empty; warnings are normal
  (upstream emits binding-loop warnings).
- Quickshell polls: first tick after (re)start reports zeros (e.g. `0 B/s`);
  real values appear from the second poll (~3s later). Don't mistake that for
  a bug.
- `qs -c ii ipc list` shows available IPC targets for toggling widgets.

## Quickshell patterns used in this fork

- Stats live in `services/ResourceUsage.qml` (Singleton, `Timer` + `FileView`
  on `/proc/*` or `/sys/*`, deltas via stored previous values + `Date.now()`).
  Format helpers (e.g. `formatSpeed`) live alongside the properties.
- Bar widgets go in `modules/ii/bar/Resources.qml` (+ `ResourcesPopup.qml`
  for hover details); mirror in `modules/ii/verticalBar/Resources.qml`.
  Throughput has no % semantic — the bar shows text (`↓ X ↑ Y`), the vertical
  bar maps activity to circle fill relative to a reference rate.
- Toggles go in `modules/common/Config.qml` under
  `Config.options.bar.resources` (e.g. `alwaysShowNetwork`).
- Quickshell service `Network.qml` covers wifi/ssid state — use it for
  connectivity, `/proc/net/dev` deltas for throughput.
