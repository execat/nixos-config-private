{ pkgs }:

with pkgs; [
  # General packages for development and system management
  alacritty
  aspell
  aspellDicts.en
  bash-completion
  coreutils findutils moreutils
  # gnused
  gcc
  neofetch
  openssh
  sqlite
  wget

  # Ocaml
  ocaml
  opam
  dune_3
  dune-release
  ocamlPackages.merlin
  ocamlPackages.ocaml-lsp
  ocamlPackages.odoc
  ocamlPackages.ocamlformat
  ocamlPackages.utop

  # Elm
  ghc
  elmPackages.elm

  # Media-related packages
  dejavu_fonts
  ffmpeg
  fd

  # Fonts
  fira-mono
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
  watchman
  wget
  zsh-powerlevel10k

  # Nix
  nix-index
  comma

  # Programming
  ## Go
  go_1_21
  gotools
  gci
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

  ## Clojure
  leiningen
  babashka

  # Linters
  shellcheck

  ## Grab essentials
  lab

  ## AWS
  awscli2 # Check against awscli

  ## Python packages
  python311
  pipenv
]
