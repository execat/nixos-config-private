# The desktop: the starter template's bspwm session

`modules/nixos/desktop.nix` is the starter template's desktop (`hosts/nixos/default.nix`) with
everything that owns hardware or machine identity removed, so it can live on a disk that is
already partitioned. `hosts/nixos/mokpo` is the only host that imports it — see that host's
README for the disks and the deploy commands.

| ported | dropped |
| --- | --- |
| lightdm + slick greeter, bspwm as default session | `modules/nixos/disk-config.nix` (disko) |
| polybar, rofi, picom, dunst, gvfs/tumbler, libinput | `networking.hostName`, `time.timeZone` |
| home-manager: `modules/nixos/{home-manager,files,packages}.nix` + `modules/shared/*` | `system.stateVersion`, kernel/bootloader settings |
| fonts, `ctrl:nocaps` xkb, NOPASSWD reboot | agenix (`modules/nixos/secrets.nix`) and the template author's SSH keys |
| the local `overlays/` (feather-font, used by the polybar config) | the fetched emacs overlay (nothing here uses it, and it is an impure fetch at eval time) |

`programs.gnupg.agent.enable`, which the template sets, is left out on purpose: with both
Plasma 6 and XFCE enabled, current nixpkgs has Plasma and XFCE each `mkDefault`
`programs.gnupg.agent.pinentryPackage`, and the option then fails with "defined multiple times
while it's expected to be unique". Pin it with `pinentryPackage = lib.mkForce pkgs.pinentry-qt;`
if you want it back.

`user`, `gitName`, `gitEmail` (the values `apps/*/apply` used to sed into files as
%USER%/%NAME%/%EMAIL%) now come from `specialArgs` in `flake.nix`. Home-manager reserves the
argument name `name` for the key in `home-manager.users`, which is why the git identity is
called `gitName`/`gitEmail`.

## Sessions and login

`services.displayManager.sddm.enable` is `false` in the host's `default.nix`: lightdm (from
`desktop.nix`) owns the display-manager slot and bspwm is `services.displayManager.defaultSession`.
Plasma 6 and XFCE are still enabled, so they remain selectable in the greeter.

`switch-to-configuration` does not restart a running display manager, so after the switch that
changes it the machine is still being served by whatever was running (SDDM, in this case) and
your current session keeps working. Log out and back in only after the new greeter is up:
`sudo systemctl restart display-manager.service` or a reboot gives you lightdm + slick with
bspwm preselected.

Keyboard hotkeys for the bspwm session are listed in `modules/nixos/README.md`.

## What home-manager writes

The first switch writes these as read-only symlinks under `/home/atm`:

    ~/.zshrc ~/.zshenv ~/.zprofile ~/.zsh/ ~/.gtkrc-2.0 ~/.emacs.d/init.el
    ~/.gnupg/gpg.conf ~/.ssh/config
    ~/.config/{alacritty,bspwm,dunst,fontconfig,git,gtk-3.0,gtk-4.0,polybar,rofi,sxhkd,tmux,udiskie}

(That list is `nix eval .#nixosConfigurations.mokpo.config.home-manager.users.atm.home.file
--apply builtins.attrNames`. The polybar, dunst, udiskie, xautolock and xss-lock user services
are written with it.)

Two notes on how they are produced:

* `modules/nixos/files.nix` writes the bspwm/sxhkd/polybar/rofi files under `/home/${user}/.config`
  — it used to derive that from `$HOME` at evaluation time, which silently wrote the wrong
  directory when the switch ran as root.
* `programs.git` writes `~/.config/git/config` with `commit.gpgsign = true` from the template,
  which needs a signing key to keep working.

## Files another tool owns: the backup policy

Four of those paths already existed on this machine, written by Plasma's GTK integration rather
than by hand:

    ~/.gtkrc-2.0  ~/.config/gtk-3.0/settings.ini  ~/.config/gtk-4.0/settings.ini  ~/.config/gtk-4.0/gtk.css

Home-manager refuses to clobber an existing file, so `desktop.nix` sets
`home-manager.backupFileExtension = "backup"`: the file in the way is renamed to `<name>.backup`
(left in place) and the symlink goes in. Without it, generation 24 failed with
`Existing file '/home/atm/.config/gtk-4.0/settings.ini' would be clobbered`; `home-manager-atm.service`
aborted, and that leaves the *entire* user environment undeployed (no bspwmrc/sxhkdrc/polybar/zsh)
while the system side switches fine. With it, generation 25 moved all four aside.

That backup name is one-shot, and Plasma can replace HM's symlink (its kconfig writer renames a
temp file over the path). The next activation then finds a file in the way again, tries to move it
to the same `<name>.backup`, and dies in HM's pre-check — exit 4 for the whole switch:

    Existing file '/home/atm/.gtkrc-2.0.backup' would be clobbered by backing up '/home/atm/.gtkrc-2.0'

`home-manager.overwriteBackup = true` (also in `desktop.nix`) makes HM delete the stale
`<name>.backup` and move the new one in, so the same collision is a warning instead:

    ... Backup will be clobbered due to HOME_MANAGER_BACKUP_OVERWRITE=1

Cost: only the newest backup of each path survives, which is fine for files holding Plasma's
defaults rather than hand-written config. After a collision, check that the symlink is back
(`ls -la ~/.gtkrc-2.0`) and read `journalctl -u home-manager-atm.service -n 5 --no-pager`. A
switch whose *configuration* is unchanged does not restart `home-manager-atm.service` at all, so
an on-disk collision is only exercised by `sudo systemctl restart home-manager-atm.service`.

Plasma keeps writing those GTK files at login; HM's are symlinks into the store, so Plasma's
writes fail (harmlessly, logged) and GTK apps under Plasma get HM's Adwaita-dark theme.

## Rough edges inherited from the template

* polybar was drawn in *every* graphical session, which is why the bspwm bar showed up over
  KDE and XFCE: home-manager's polybar module hardcodes `Install.WantedBy = [ "tray.target" ]`
  and `tray.target` is pulled into Plasma/XFCE sessions too. Fixed in
  `modules/nixos/home-manager.nix` with
  `systemd.user.services.polybar.Install.WantedBy = lib.mkForce [ ];` — `bspwmrc` starts it
  explicitly (`systemctl --user start polybar`), which works whether or not the unit is
  enabled. `udiskie`, `xautolock-session` and `xss-lock` are still session-scoped to every
  graphical session (they run under Plasma right now); gate them the same way if you want
  them bspwm-only. `dunst` is D-Bus activated and Plasma owns the notifications name, so it
  stays out of the way there.
* `~/.config/bspwm/bspwmrc` finishes by waiting for an emacs daemon that nothing starts
  (`emacsclient -a "" -e '(progn)'` in a `while` loop) — the template's emacs service is
  commented out. bspwm, sxhkd and polybar are already running by then, so it only spins;
  enable home-manager's `services.emacs.enable = true` or delete that block to stop it.
* Rebuild warnings: `programs.ssh.matchBlocks` is deprecated in current home-manager (use
  `programs.ssh.settings`), and the template's `home.stateVersion = "21.05"` triggers the
  `gtk.gtk4.theme` legacy-default warning. Both live in `modules/{shared,nixos}/home-manager.nix`,
  which the darwin host shares.
* `programs.git` sets `commit.gpgsign = true`, so commits fail until a signing key exists
  (or you drop that line).
* `modules/shared/packages.nix` is the template's big per-user package set (google-chrome,
  terraform, awscli2, go, rustc, openjdk, python3, nodejs_24, docker-compose, …). It is why
  the first switch pulls several GB; trim that file if you don't want the whole set.
