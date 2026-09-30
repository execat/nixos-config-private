{ pkgs, config, ... }:

# let
#  githubPublicKey = "ssh-ed25519 AAAA...";
# in
{

  # ".ssh/id_github.pub" = {
  #   text = githubPublicKey;
  # };

  # Initializes Emacs with org-mode so we can tangle the main config
  ".emacs.d/init.el" = {
    text = builtins.readFile ../shared/config/emacs/init.el;
  };

  # init.el reads ~/.config/emacs/config.org (or $EMACS_CONFIG_ORG) and tangles it; with no
  # such file it downloads the upstream template config to ~/.emacs.d/default-config.org and
  # tangles that instead. This repo no longer ships a config.org: add a
  # ".config/emacs/config.org" entry here if you want Nix to manage one.
}
