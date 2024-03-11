{ pkgs, config, ... }:

{
  # Initializes Emacs with org-mode so we can tangle the main config
  ".config/emacs.clean/init.el" = {
    text = builtins.readFile ../shared/config/emacs/init.el;
  };

  ".emacs.d".source = pkgs.fetchFromGitHub {
     owner = "plexus";
     repo = "chemacs2";
     rev = "c2d700b";
     sha256 = "sha256-/WtacZPr45lurS0hv+W8UGzsXY3RujkU5oGGGqjqG0Q=";
  };

  ".emacs-profiles.el" = {
    text = builtins.readFile ../shared/config/emacs-profiles.el;
  };

  ".config/amethyst/amethyst.yml" = {
    text = builtins.readFile ../shared/config/amethyst.yml;
  };

  ".bundle/config" = {
    text = ''
      ---
      BUNDLE_PATH: .bundle
    '';
  };
}
