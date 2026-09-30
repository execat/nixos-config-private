# nixos-config

Flake-managed NixOS and macOS ([nix-darwin](https://github.com/nix-darwin/nix-darwin)) configuration.

## The three consumers

| configuration | what it is | identity lives in |
| --- | --- | --- |
| `mokpo` — also reachable as `x86_64-linux` | the real laptop (x86_64-linux). Owns its own LUKS containers and filesystems, so it takes no disko module | `hosts/nixos/mokpo/` |
| `starter` / `aarch64-linux` | the upstream starter host: disko + placeholder disk (`%DISK%`) and user, bspwm/lightdm desktop. Only useful on a machine you are about to wipe and install with disko | `hosts/nixos/` |
| `aarch64-darwin` / `x86_64-darwin` | the Mac | `hosts/darwin/` |

`mokpo` is also aliased to `x86_64-linux` so that the bare commands — which target the platform
host — can only ever build something that boots this laptop. Anything that reformats a disk lives
under a different name (`starter`, `aarch64-linux`).

## Layout

```
apps/<system>/<name>   scripts behind the flake's apps.<system>.<name> outputs
hosts/nixos/mokpo/     the laptop: default.nix + hardware-configuration.nix + secrets.nix
hosts/nixos/           the starter host (disko, placeholders) — fresh installs only
hosts/darwin/          the Mac's system config
modules/shared/        config both platforms import (zsh, git, ssh, tmux, emacs, packages)
modules/nixos/         the desktop (bspwm/polybar/rofi) and per-user NixOS config
modules/darwin/        homebrew casks, dock, per-user macOS config
overlays/              applied automatically by modules/shared/default.nix
secrets/*.age          age-encrypted secrets (see secrets/README.md)
agenix-rules.nix       the recipient list the agenix CLI reads
```

## Deploy

```sh
# the laptop
sudo nixos-rebuild switch --flake .#mokpo
sudo nixos-rebuild switch --flake .#             # bare form: picks the attribute named after /etc/hostname
sudo nixos-rebuild boot   --flake .#mokpo        # bootloader entries + next boot, without switching

# the Mac
sudo ./result/sw/bin/darwin-rebuild switch --flake .#aarch64-darwin
```

Flakes only see files git knows about: `git add` any new file before switching or the build uses
the last staged version.

## flake apps

`apps.<system>.{apply,build-switch,clean}` exist for the Linux systems and
`apps.<system>.{apply,build,build-switch,clean}` for the darwin ones; each is a thin wrapper that
execs `apps/<system>/<name>` from the flake source.

⚠ They are declared but currently unusable: every script under `apps/` is committed mode `100644`,
so the wrapper's `exec` fails with `Permission denied`. Either `chmod +x apps/*/*` (git records the
bit) or call the script with an interpreter: `bash apps/x86_64-linux/build-switch --host mokpo`.

## Documentation

| document | covers |
| --- | --- |
| `hosts/nixos/mokpo/README.md` | the laptop's disks, deploy commands, recovery ladder |
| `hosts/nixos/mokpo/SECRETS.md` | what mokpo decrypts today, host-key identity, the nix-secrets plan |
| `modules/nixos/README.md` | module layout, how to add a host, bspwm hotkeys |
| `modules/nixos/DESKTOP.md` | the ported starter desktop: what it drops, sessions/login, backup policy, rough edges |
| `modules/darwin/README.md` | the Mac's modules and their current state |
| `modules/shared/README.md` | what both platforms share |
| `secrets/README.md` | agenix CLI workflow, adding or rekeying a secret |
| `overlays/README.md` | what is in `overlays/` |
| `diff-branches-dev-old.md` | how this tree differs from the old `execat/nixos-config-private` layout (snapshot) |
