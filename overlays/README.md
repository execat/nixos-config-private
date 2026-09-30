# Overlays

Files in this directory run automatically as part of each build.
`modules/shared/default.nix` and `modules/nixos/desktop.nix` both add every file here via
`builtins.readDir`, so dropping a `.nix` file in is all it takes. Some common ways I've used
overlays in the past:
* Applying patches
* Downloading different versions of files (locking to a version or trying a fork)
* Workarounds and stuff I need to run temporarily

In here today:

* `10-feather-font.nix` — adds `pkgs.feather-font` (fetchzip of
  `dustinlyons/feather-font` v1.0). Polybar uses it as `font1` (`modules/nixos/home-manager.nix`)
  and the rofi `.rasi` files name it too; `desktop.nix` also installs it into `fonts.packages`.

`modules/shared/default.nix` additionally appends an emacs overlay fetched at evaluation time —
see that directory's README.
