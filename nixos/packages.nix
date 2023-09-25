{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [
  # Security and authentication
  yubikey-manager
  yubikey-manager-qt
  yubikey-agent

  # App and package management
  appimage-run
  gnumake
  cmake
  home-manager

  # Media and design tools
  vlc
  fontconfig
  font-manager

  # Calculators
  bc # old school calculator
  galculator

  # Testing and development tools
  direnv

  # Text and terminal utilities

  # Other utilities
  firefox

  # PDF viewer
  zathura
]
