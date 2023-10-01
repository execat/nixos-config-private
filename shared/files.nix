{ pkgs, config, ... }:

{
  # Initializes Emacs with org-mode so we can tangle the main config
  ".emacs.d/init.el" = {
    text = builtins.readFile ../shared/config/emacs/init.el;
  };

  ".config/amethyst/amethyst.yml" = {
    text = builtins.readFile ../shared/config/amethyst.yml;
  };
}
