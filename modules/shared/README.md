# Shared

Config both platforms import — NixOS through `modules/nixos/home-manager.nix`, macOS through
`modules/darwin/home-manager.nix`. Shell, git, ssh, tmux, the terminal, and the emacs bootstrap.

## Layout

```
.
├── config             # files not written in Nix (p10k.zsh, emacs/init.el)
├── default.nix        # nixpkgs config + overlays: everything in ../../overlays/, plus a fetched emacs overlay
├── files.nix          # non-Nix, static files written into $HOME (~/.emacs.d/init.el)
├── home-manager.nix   # the goods; most all shared config lives here
├── packages.nix       # packages shared by both platforms
```

`home-manager.nix` is the file both hosts share directly. `hosts/darwin/default.nix` and the
starter host `hosts/nixos/default.nix` import this whole directory (so they also pick up
`default.nix`); `hosts/nixos/mokpo` reaches `home-manager.nix` / `files.nix` / `packages.nix`
through `modules/nixos/home-manager.nix` and takes its overlays from `modules/nixos/desktop.nix`
instead.

`default.nix` appends a `builtins.fetchTarball` of `dustinlyons/emacs-overlay` at evaluation time.
That is an impure eval-time fetch, and only the darwin host needs it: `emacs-unstable`, which
`hosts/darwin/default.nix` installs, does not exist in this flake's nixpkgs. No NixOS host names a
package from it.
