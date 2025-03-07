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
  rlwrap
  sqlite

  # Encryption and security tools
  age
  age-plugin-yubikey
  gnupg
  libfido2
  # pinentry
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

  # Categorize later
  curl wget
  cmake libtool
  fasd
  pstree
  tokei
  tree
  unixtools.watch
  zsh-powerlevel10k

  # Languages: Practical
  elixir
  elixir-ls
  go
  ghc
  haskellPackages.lsp
  stack # Use ghc using "stack ghci"

  # Languages: Practical: Node.js development tools
  nodejs
  nodePackages.typescript
  nodePackages.typescript-language-server
  yarn

  # Languages: Practical: Python
  pipenv
  python313
  python313Packages.poetry-core
  python313Packages.virtualenv

  # Languages: Practical: Ruby
  libyaml
  ruby_3_4
  rubyPackages_3_4.pry
  rubyPackages_3_4.parallel
  rubyPackages_3_4.rails
  rubyPackages_3_4.awesome_print
  rubyPackages_3_4.rest-client
  rubyPackages_3_4.ruby-lsp

  # Languages: Practical: Rust
  # rustup
  rustc
  cargo
  rust-analyzer
  rustfmt
  # evcxr # Use it by calling `nix-shell -p '[libiconv rust-analyzer rustfmt clippy evcxr]'`
  wabt

  # Languages: Learning: Lisps
  chez
  clojure-lsp
  leiningen
  sbcl

  # Languages: Learning
  elmPackages.elm
  elmPackages.elm-language-server
  lua5_4
  lua-language-server
  nil # Nix
  opam
  swi-prolog

  # SCM
  git
  fossil
  mercurial

  # Web
  lynx
  w3m

  # Servers
  darkhttpd
  nginx

  cachix
  entr
  graphviz
]
