# Darwin (the Mac)

Machine identity lives in `../../hosts/darwin/default.nix` — it sets no hostname, only the user,
nix settings, the launchd emacs agent and `system.defaults`. This directory is the reusable half.

## Layout

```
.
├── casks.nix          # homebrew casks installed via nix-homebrew
├── dock/default.nix   # declarative dock (local.dock.*), entries listed in home-manager.nix
├── files.nix          # ~/.local/share/bin/emacsclient (the Raycast "Run Emacs" script)
├── home-manager.nix   # homebrew + the user's home-manager setup + dock entries
├── packages.nix       # shared packages + dockutil
```

`darwinConfigurations.aarch64-darwin` and `.x86_64-darwin` in `flake.nix` both build
`hosts/darwin`, one per platform.

## State (verified 2026-10-01)

| | |
| --- | --- |
| `aarch64-darwin` | evaluates: `nix eval .#darwinConfigurations.aarch64-darwin.config.home-manager.users.atm.home.username` → `atm`. `programs.git.settings.commit.gpgsign = true` (unlike NixOS, this side expects a signing key) |
| `x86_64-darwin` | the system half evaluates, the **user** half does not — `error: Nixpkgs 26.11 has dropped support for x86_64-darwin` |
| secrets | none: `age.secrets` is empty for both configs. The template's stub `modules/darwin/secrets.nix` was removed, so agenix is wired up but idle — `secrets/README.md` and `agenix-rules.nix` are mokpo-only |

The `x86_64-darwin` failure is the Intel Mac (`goyang`) on nixpkgs 26.11, which dropped that
platform. The flake's own `nixpkgs` still supports it (hence the system half evaluating), but
`home-manager` no longer follows `nixpkgs` — in `flake.lock` its nixpkgs comes from `agenix`
(`nixpkgs_3`), and that newer pin is the one raising the error. Two ways out: give home-manager the
flake's nixpkgs back (`home-manager.inputs.nixpkgs.follows = "nixpkgs"`), or pin the input to
`github:NixOS/nixpkgs/nixpkgs-26.05-darwin` as the error message suggests.

`homebrew.onActivation` is intentionally reduced to a commented `cleanup = "uninstall"`; the old
`autoUpdate`/`upgrade`/`cleanup = "zap"` block and the GPG-key-import LaunchAgent were dropped when
this tree was restructured.
