# mokpo

The actual machine (x86_64-linux laptop), ported into the repo from its `/etc/nixos` on
2026-09-28.

## Files

| file | origin |
| --- | --- |
| `default.nix` | copy of `/etc/nixos/configuration.nix` (only the header comment changed) |
| `hardware-configuration.nix` | verbatim copy of `/etc/nixos/hardware-configuration.nix` |

`default.nix` imports `./hardware-configuration.nix`, exactly like `/etc/nixos` did, so this
directory is a drop-in replacement for the two files that were living in `/etc/nixos`.

## Disks it must keep booting

| device | size | how it is used |
| --- | --- | --- |
| `nvme0n1p1` | 1 GiB | vfat, UUID `4F27-388E`, mounted at `/boot` (EFI system partition) |
| `nvme0n1p2` | 447.8 GiB | LUKS `93dd5e3f-6d12-4c1f-aa79-f8959ebdc12c` → ext4, mounted at `/` |
| `nvme0n1p3` | 17 GiB | LUKS `a7d4c564-9abe-4be7-946e-2ddbd385338e` → swap |

Bootloader is systemd-boot on the ESP. Both LUKS containers are opened in initrd
(`boot.initrd.luks.devices`), which is why those two UUIDs must stay correct.

## Deploy

`mokpo` and `x86_64-linux` are the same system in `flake.nix`, so the bare commands — which
target the platform host — hit this machine too, and never the destroy-the-disk starter host.

```sh
# from this repo checkout (any of these build this host)
sudo nixos-rebuild switch --flake .#mokpo
sudo nixos-rebuild switch --flake .#x86_64-linux
sudo nixos-rebuild switch --flake .          # picks the attribute named after /etc/hostname

# or via the repo's wrapper app
nix run .#build-switch -- --host mokpo

# write bootloader entries + make it the next boot without switching the running system
sudo nixos-rebuild boot --flake .#mokpo
```

Flakes only see files git knows about: `git add` any file you add or edit before switching, or
the build silently uses the last staged/committed version.

## Desktop: the starter template's bspwm session

This host imports `modules/nixos/desktop.nix`, which is the starter template's desktop
(`hosts/nixos/default.nix`) with everything that owns hardware or machine identity removed,
so it can live on a disk that is already partitioned:

| ported | dropped |
| --- | --- |
| lightdm + slick greeter, bspwm as default session | `modules/nixos/disk-config.nix` (disko) |
| polybar, rofi, picom, dunst, gvfs/tumbler, libinput | `networking.hostName`, `time.timeZone` |
| home-manager: `modules/nixos/{home-manager,files,packages}.nix` + `modules/shared/*` | `system.stateVersion`, kernel/bootloader settings |
| fonts, `ctrl:nocaps` xkb, NOPASSWD reboot | agenix (`modules/nixos/secrets.nix`) and the template author's SSH keys |
| the local `overlays/` (feather-font, used by the polybar config) | the fetched emacs overlay (nothing here uses it, and it is an impure fetch at eval time) |

`programs.gnupg.agent.enable`, which the template sets, is left out on purpose: with both
Plasma 6 and XFCE enabled in `default.nix`, current nixpkgs has Plasma and XFCE each
`mkDefault` `programs.gnupg.agent.pinentryPackage`, and the option then fails with
"defined multiple times while it's expected to be unique". Pin it with
`pinentryPackage = lib.mkForce pkgs.pinentry-qt;` if you want it back.

`user`, `gitName`, `gitEmail` (the values `apps/*/apply` used to sed into files as
%USER%/%NAME%/%EMAIL%) now come from `specialArgs` in `flake.nix`. Home-manager reserves
the argument name `name` for the key in `home-manager.users`, which is why the git
identity is called `gitName`/`gitEmail`.

### Sessions and login

`services.displayManager.sddm.enable` is `false` here: lightdm (from `desktop.nix`) owns
the display-manager slot and bspwm is `services.displayManager.defaultSession`. Plasma 6
and XFCE are still enabled in `default.nix`, so they remain selectable in the greeter.

### Dotfiles home-manager will take over

The first switch writes these as read-only symlinks under `/home/atm`; move any real file
of the same name aside first (home-manager refuses to clobber, with a `.backup` suffix):

    ~/.zshrc ~/.zshenv ~/.zprofile ~/.zsh/ ~/.gtkrc-2.0 ~/.emacs.d/init.el
    ~/.gnupg/gpg.conf ~/.ssh/config
    ~/.config/{alacritty,bspwm,dunst,fontconfig,git,gtk-3.0,gtk-4.0,polybar,rofi,sxhkd,tmux,udiskie}

(That list is `nix eval .#nixosConfigurations.mokpo.config.home-manager.users.atm.home.file
--apply builtins.attrNames`. The polybar, dunst, udiskie, xautolock and xss-lock user
services are written with it.)

Note that home-manager's `programs.git` writes `~/.config/git/config` (with
`commit.gpgsign = true` from the template, which needs a signing key to keep working),
and `modules/nixos/files.nix` writes the bspwm/sxhkd/polybar/rofi files under
`/home/${user}/.config` — it used to derive that from `$HOME` at evaluation time, which
silently wrote the wrong directory when the switch ran as root.

Keyboard hotkeys for the bspwm session are listed in `modules/nixos/README.md`.

### Rough edges inherited from the template

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

## If a switch leaves the machine unbootable

Nothing gets replaced until the build succeeds, and the boot menu keeps every generation, so
there is always something working to fall back to:

1. Reboot. systemd-boot shows a 5 s menu (`timeout 5` in `/boot/loader/loader.conf`); pick the
   previous `Generation N` entry, which is the last system that booted.
2. Once booted, make it permanent: `sudo nixos-rebuild switch --rollback` (or
   `sudo nixos-rebuild boot --rollback` to also fix the bootloader default).
3. Fix the repo, or fall back to the untouched `/etc/nixos` copy: plain `sudo nixos-rebuild
   switch` (no `--flake`) rebuilds `configuration.nix` + `hardware-configuration.nix` there.
4. Worst case: any NixOS USB installer can mount `/dev/nvme0n1p2` via `cryptsetup`, then
   `nixos-enter` into it.

The ESP holds each generation's kernel/initrd copy under `/boot/EFI/nixos` (154 MiB used,
869 MiB free); adding `boot.loader.systemd-boot.configurationLimit = 42;` bounds that growth if
it ever gets tight.

## Do not import `modules/nixos/disk-config.nix` here

The shared template host (`hosts/nixos/default.nix`) gets its disks from disko. disko's NixOS
module turns `disko.devices` into `fileSystems`/`swapDevices`, so importing it for this host
would replace the real LUKS/ext4/vfat definitions with the template's placeholder disk device
and the machine would not boot. This host describes its disks with
`hardware-configuration.nix` instead.
