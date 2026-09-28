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
(`boot.initrd.luks.devices`), which is why those two UUIDs must stay correct. This host takes its
filesystems from `hardware-configuration.nix` and must never import
`modules/nixos/disk-config.nix` (disko): that would replace them with the template's placeholder
disk device and the machine would not boot.

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

## Secrets

`secrets.nix` in this directory wires [agenix](https://github.com/ryantm/agenix) in for this host.
The encrypted blobs live in `secrets/` at the repo root, recipients are declared in
`agenix-rules.nix`, and decryption uses this machine's own SSH host keys at activation — so there
is no separate age key to generate, copy onto the machine or keep anywhere. The first secret is the
GitHub SSH key at `~/.ssh/id_github`, which is the path the ssh settings already point
`IdentityFile` at. Editing them needs no extra tooling beyond the `agenix` CLI that
`default.nix` puts in `environment.systemPackages`; the workflow, the reinstall caveat and
how to add one: `secrets/README.md`. The host-specific side of it — what the identity is, which
secret lands where, and the plan for moving the blobs to the private `execat/nix-secrets` repo
together with the keys that needs: `SECRETS.md`.

## Desktop, sessions and dotfiles

`default.nix` imports `modules/nixos/desktop.nix` (the starter template's bspwm/lightdm/polybar
session) and home-manager owns `/home/atm`. What was ported from the template and what was left
behind, how login behaves after the display-manager change, the backup policy for the files
Plasma also writes, and the rough edges to expect: `modules/nixos/DESKTOP.md`.

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
