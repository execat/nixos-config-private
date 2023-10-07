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

  # Encryption and security tools
  age
  age-plugin-yubikey
  gnupg
  libfido2
  pinentry
  yubikey-manager

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

  # Categorize later
  curl
  fasd
  pstree
  tree
  wget
  zsh-powerlevel10k

  # Languages: Practical
  adoptopenjdk-bin
  elixir
  go
  haskellPackages.ghc
  nodejs
  nodePackages.typescript
  nodePackages.typescript-language-server
  pipenv
  python311

  # Languages: Practical: Rust
  # rustup
  rustc
  cargo
  rust-analyzer
  rustfmt
  # evcxr # Use it by calling `nix-shell -p '[libiconv rust-analyzer rustfmt clippy evcxr]'`
  wabt

  # Languages: Learning
  chez
  elmPackages.elm
  erlang
  leiningen
  lua5_4
  swiProlog
  yarn
  stack # Use ghc using "stack ghci"
  opam

  # SCM
  git

  # SCM alternatives
  fossil
  mercurial

  # Web
  lynx
  w3m

  # Servers
  darkhttpd
  nginx

  # Text editors
  neovim

  # Ruby
  ruby_3_2
  rubyPackages_3_2.pry
  rubyPackages_3_2.parallel
  rubyPackages_3_2.rails
  rubyPackages_3_2.awesome_print
  rubyPackages_3_2.rest-client

  duti # Change default applications for extensions
  ffmpeg-full
  graphviz
  cachix
]
