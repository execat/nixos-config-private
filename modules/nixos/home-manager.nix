{ config, pkgs, lib, user, gitName, gitEmail, ... }:

let
  xdg_configHome  = "/home/${user}/.config";
  shared-programs = import ../shared/home-manager.nix { inherit config pkgs lib user gitName gitEmail; };
  shared-files = import ../shared/files.nix { inherit config pkgs; };

  polybar-user_modules = builtins.readFile (pkgs.replaceVars ./config/polybar/user_modules.ini {
    packages = "${xdg_configHome}/polybar/bin/check-nixos-updates.sh";
    searchpkgs = "${xdg_configHome}/polybar/bin/search-nixos-updates.sh";
    launcher = "${xdg_configHome}/polybar/bin/launcher.sh";
    powermenu = "${xdg_configHome}/rofi/bin/powermenu.sh";
    calendar = "${xdg_configHome}/polybar/bin/popup-calendar.sh";
  });

  polybar-config = pkgs.replaceVars ./config/polybar/config.ini {
    font0 = "DejaVu Sans:size=12;3";
    font1 = "feather:size=12;3"; # from overlay
  };

  polybar-modules = builtins.readFile ./config/polybar/modules.ini;
  polybar-bars = builtins.readFile ./config/polybar/bars.ini;
  polybar-colors = builtins.readFile ./config/polybar/colors.ini;

in
{
  home = {
    enableNixpkgsReleaseCheck = false;
    username = "${user}";
    homeDirectory = "/home/${user}";
    packages = pkgs.callPackage ./packages.nix {};
    file = shared-files // import ./files.nix { inherit user; };
    stateVersion = "21.05";
  };

  # Use a dark theme
  gtk = {
    gtk4.theme = null;        # Disabling old behavior
    enable = true;
    iconTheme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
  };

  # Screen lock
  services = {
    screen-locker = {
      enable = true;
      inactiveInterval = 10;
      lockCmd = "${pkgs.i3lock-fancy-rapid}/bin/i3lock-fancy-rapid 10 15";
    };

    # Auto mount devices
    udiskie.enable = true;

    polybar = {
      enable = true;
      config = polybar-config;
      extraConfig = polybar-bars + polybar-colors + polybar-modules + polybar-user_modules;
      package = pkgs.polybarFull;
      script = "polybar main &";
    };

    dunst = {
      enable = true;
      package = pkgs.dunst;
      settings = {
        global = {
          monitor = 0;
          follow = "mouse";
          border = 0;
          height = 400;
          width = 320;
          offset = "33x65";
          indicate_hidden = "yes";
          shrink = "no";
          separator_height = 0;
          padding = 32;
          horizontal_padding = 32;
          frame_width = 0;
          sort = "no";
          idle_threshold = 120;
          font = "Noto Sans";
          line_height = 4;
          markup = "full";
          format = "<b>%s</b>\n%b";
          alignment = "left";
          transparency = 10;
          show_age_threshold = 60;
          word_wrap = "yes";
          ignore_newline = "no";
          stack_duplicates = false;
          hide_duplicate_count = "yes";
          show_indicators = "no";
          icon_position = "left";
          icon_theme = "Adwaita-dark";
          sticky_history = "yes";
          history_length = 20;
          history = "ctrl+grave";
          browser = "google-chrome-stable";
          always_run_script = true;
          title = "Dunst";
          class = "Dunst";
          max_icon_size = 64;
        };
      };
    };
  };

  # gpg.enable keeps gpg around for reading/verifying keys, but commit signing stays OFF on
  # NixOS. The signing key (997C58F864FFEBB4) only exists in the Mac's keyring: this box has no
  # secret key (and no pinentry either), so `git commit` died with
  #   error: gpg failed to sign the data: gpg: skipped "...": No secret key
  #   fatal: failed to write commit object
  # Re-enable per host (commit.gpgsign = true) once a key is imported and gpg-agent has a
  # pinentry to prompt with.
  programs = shared-programs // {
    gpg.enable = true;
    git = shared-programs.git // {
      settings = shared-programs.git.settings // { commit.gpgsign = false; };
    };
  };

  # polybar belongs to the bspwm session only. home-manager's polybar module hardcodes
  # `Install.WantedBy = [ "tray.target" ]`, and tray.target is pulled into *every* graphical
  # session, so the bar was drawn over Plasma and XFCE too. bspwmrc starts it explicitly
  # (`systemctl --user start polybar`), which works whether or not the unit is enabled, so
  # drop the session-wide autostart. Same story for the other session-scoped helpers below
  # (udiskie, screen-locker) if you only want them under bspwm.
  systemd.user.services.polybar.Install.WantedBy = lib.mkForce [ ];

}
