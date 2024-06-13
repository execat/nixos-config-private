{ pkgs, config, ... }:

{
  # Config dir files
  ".config/amethyst/amethyst.yml" = {
    text = builtins.readFile ../shared/config/amethyst.yml;
  };

  # Initializes Emacs with org-mode so we can tangle the main config
  ".config/emacs.clean/init.el" = {
    text = builtins.readFile ../shared/config/emacs/init.el;
  };

  ".config/emacs.doom".source = pkgs.fetchFromGitHub {
     owner = "doomemacs";
     repo = "doomemacs";
     rev = "813c961";
     sha256 = "sha256-N2pwgbWI5cbTJETt0umoM+a+Exh6REcjWIEE3YOEogI=";
  };

  # Home directory files
  ".emacs.d".source = pkgs.fetchFromGitHub {
     owner = "plexus";
     repo = "chemacs2";
     rev = "c2d700b";
     sha256 = "sha256-/WtacZPr45lurS0hv+W8UGzsXY3RujkU5oGGGqjqG0Q=";
  };

  ".emacs-profiles.el" = {
    text = builtins.readFile ../shared/config/emacs-profiles.el;
  };

  ".bundle/config" = {
    text = ''
      ---
      BUNDLE_PATH: .bundle
    '';
  };
}
