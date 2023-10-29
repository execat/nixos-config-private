{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [
  # App and package management
  appimage-run
  home-manager
  vscode        # vscodium for free alternative
]
