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

```sh
# from this repo checkout
sudo nixos-rebuild switch --flake .#mokpo

# or via the repo's wrapper app
nix run .#build-switch -- --host mokpo

# write bootloader entries + make it the next boot without switching the running system
sudo nixos-rebuild boot --flake .#mokpo
```

## Do not import `modules/nixos/disk-config.nix` here

The shared template host (`hosts/nixos/default.nix`) gets its disks from disko. disko's NixOS
module turns `disko.devices` into `fileSystems`/`swapDevices`, so importing it for this host
would replace the real LUKS/ext4/vfat definitions with the template's placeholder disk device
and the machine would not boot. This host describes its disks with
`hardware-configuration.nix` instead.
