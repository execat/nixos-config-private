{ pkgs }:

with pkgs; [
  # General packages for development and system management
  aspell
  aspellDicts.en
  bash-completion
  coreutils
  findutils
  moreutils
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
  ffmpeg-full
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

  # Categorize later
  curl
  cmake libtool
  fasd
  pstree
  tokei
  tree
  wget
  unixtools.watch
  wget
  zsh-powerlevel10k

  # Languages: Practical
  elixir
  go
  haskellPackages.ghc
  nodejs
  nodePackages.typescript
  nodePackages.typescript-language-server
  pipenv
  python311
  virtualenv

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
  nil # Nix
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

  # Ruby
  libyaml
  ruby_3_3
  rubyPackages_3_3.pry
  rubyPackages_3_3.parallel
  rubyPackages_3_3.rails
  rubyPackages_3_3.awesome_print
  rubyPackages_3_3.rest-client

  cachix
  entr
  graphviz
  watch
]
