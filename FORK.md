# dots-hyprland fork notes

> This file lives on the `custom` branch only (never on `main`), so it
> travels with the fork to other machines. Clone with
> `git clone -b custom git@github.com:afazzdev/dots-hyprland.git`.

Fork: https://github.com/afazzdev/dots-hyprland
Upstream (mainline): https://github.com/end-4/dots-hyprland
Local clone: ~/dots-hyprland

## Remotes (do not change)
- `origin`   = git@github.com:afazzdev/dots-hyprland.git (our fork, SSH)
- `upstream` = https://github.com/end-4/dots-hyprland (mainline)

Check with: `git remote -v`

## Branches (rule: never commit to main)
- `main`   = pristine mirror of upstream/main. Only fast-forward from upstream.
- `custom` = our tweaks. All personal changes go here.

You are normally on: `custom`

Customized files (Quickshell resource widgets):
- dots/.config/quickshell/ii/modules/common/Config.qml
- dots/.config/quickshell/ii/modules/ii/bar/Resources.qml
- dots/.config/quickshell/ii/modules/ii/bar/ResourcesPopup.qml
- dots/.config/quickshell/ii/modules/ii/verticalBar/Resources.qml
- dots/.config/quickshell/ii/services/ResourceUsage.qml

## SSH / identity
- Key: `~/.ssh/id_ed25519` (add the `.pub` to GitHub under SSH keys)
- Test: `ssh -T git@github.com` should greet you with your username
- Commits use a private noreply address so no personal email leaks into history
- New machine: generate key, add pubkey to GitHub, then clone via SSH.

## Workflows

### Daily work (on custom)
```bash
git checkout custom
# edit files
git add <files>
git commit -m "custom: ..."
git push origin custom
```

### Receive mainline updates
```bash
git checkout main
git fetch upstream
git pull --ff-only upstream main
git push origin main
git checkout custom
git rebase main
# resolve conflicts if any, then:
git push --force-with-lease origin custom
```

### Install / update dotfiles on system
```bash
./setup exp-update
# or: ./setup exp-merge
```

## Deploying quickshell changes (IMPORTANT)
Live config is a COPY at ~/.config/quickshell/ii — editing the repo alone
changes nothing on screen. After editing repo files:
```bash
REPO=~/dots-hyprland/dots/.config/quickshell/ii; DEST=~/.config/quickshell/ii
cp -f "$REPO/services/ResourceUsage.qml" "$DEST/services/ResourceUsage.qml"
# ... repeat for each changed file ...
setsid qs -c ii -d </dev/null >/tmp/qs-restart.log 2>&1 < /dev/null & disown
```
(Careful: `pkill -f "qs -c ii"` also matches your own shell — anchor with `^qs`.)
Check: `pgrep -x qs`, `grep -i error /tmp/qs-restart.log`

## DO NOT
- Do not commit directly to `main`
- Do not `git push origin main` unless main is a clean fast-forward from upstream
- Do not delete `upstream` remote
