{ pkgs }:

with pkgs; [
  # General packages for development and system management
  alacritty
  aspell
  aspellDicts.en
  bash-completion
  coreutils
  gcc
  neofetch
  openssh
  sqlite
  wget

  # Media-related packages
  dejavu_fonts
  ffmpeg
  fd
  font-awesome
  glow
  hack-font
  jetbrains-mono
  meslo-lgs-nf

  # Node.js development tools
  fzf
  nodejs

  # Text and terminal utilities
  htop
  jq
  ripgrep
  tree
  tmux
  zsh-powerlevel10k

  # Python packages
  python311
  python311Packages.virtualenv
]
