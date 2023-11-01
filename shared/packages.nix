{ pkgs }:

with pkgs; [
  # General packages for development and system management
  alacritty
  aspell
  aspellDicts.en
  bash-completion
  coreutils findutils moreutils
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
  nodejs

  # Text and terminal utilities
  curl
  fasd
  pstree
  tokei
  tree
  unixtools.watch
  wget
  zsh-powerlevel10k

  # Programming
  ## Go
  go_1_21
  gotools
  golangci-lint
  gopls
  go-outline
  gopkgs
  protobuf
  grpc-gateway
  protoc-gen-go
  protoc-gen-go-grpc
  go-bindata
  go-swagger
  go-mockery
  gum

  ## Grab essentials
  lab

  ## AWS
  awscli2 # Check against awscli

  ## Python packages
  python311
  python311Packages.virtualenv
]
