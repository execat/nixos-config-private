# The starter template's desktop, on a machine whose disks are already set up.
#
# This is `hosts/nixos/default.nix` (bspwm + lightdm/slick + polybar + rofi + picom +
# dunst, with home-manager managing the user's UI dotfiles) minus everything that owns
# hardware or machine identity, so it can be imported by a host that lives on a real,
# already-partitioned disk:
#
#   * no `modules/nixos/disk-config.nix` (disko would replace this host's fileSystems)
#   * no hostname, time zone, stateVersion, kernel or bootloader settings
#   * no agenix / host secrets
#   * no SSH `authorizedKeys` from the template author
#
# The UI itself is the same code the starter host uses:
#   modules/nixos/home-manager.nix  (polybar, dunst, rofi, bspwmrc, sxhkdrc, gtk, ...)
#   modules/nixos/files.nix         (bspwm/sxhkd/polybar/rofi config files)
#   modules/nixos/packages.nix      (per-user packages)
#   modules/shared/*                (zsh, alacritty, tmux, ssh, git, emacs init)
#
# `user`, `gitName`, `gitEmail` come from the flake's `specialArgs` (they replaced the
# template's %USER%/%NAME%/%EMAIL% tokens, which is what `apps/*/apply` used to sed in).
# They are not called `name`/`email` because home-manager's per-user submodule already
# takes an argument named `name` (the attribute key in `home-manager.users`), and
# `extraSpecialArgs` would silently shadow it.
#
{ config, pkgs, lib, inputs, user, gitName, gitEmail, ... }:

let
  # Apply each overlay found in the /overlays directory. (The starter also adds a
  # fetched emacs overlay here; nothing in this repo's NixOS config uses it, and the
  # fetch is an impure network fetch at evaluation time, so it is left out.)
  overlayPath = ../../overlays;
  localOverlays = with builtins;
    map (n: import (overlayPath + ("/" + n)))
        (filter (n: match ".*\\.nix" n != null ||
                    pathExists (overlayPath + ("/" + n + "/default.nix")))
                (attrNames (readDir overlayPath)));
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    };

    overlays = localOverlays; # feather-font, used by the polybar config
  };

  # home-manager owns the desktop dotfiles for this user.
  #
  # backupFileExtension: Plasma writes ~/.gtkrc-2.0 and ~/.config/gtk-{3,4}.0/{settings.ini,gtk.css}
  # itself (breeze cursors, set on first login), and home-manager's gtk module wants those same
  # paths. Without this, `home-manager-atm.service` fails on activation with "Existing file
  # ... would be clobbered" and the rest of the user environment never gets deployed. With it,
  # home-manager renames the existing file to `<file>.backup` and carries on. Drop the line if
  # you would rather the switch fail loudly than move files.
  #
  # overwriteBackup: that backup name is one-shot. Once `.gtkrc-2.0.backup` exists, the *next*
  # time anything rewrites the file (Plasma again on the next login) activation dies in its
  # pre-check with
  #   Existing file '/home/atm/.gtkrc-2.0.backup' would be clobbered by backing up '/home/atm/.gtkrc-2.0'
  # and the whole switch exits 4, even though the system config itself activated fine. With this
  # on, home-manager deletes the stale `<file>.backup` and moves the new one in, so repeated
  # collisions are harmless. Trade-off: only the latest backup survives (fine at this scale —
  # the file it replaces is a Plasma default, not user data).
  home-manager = {
    backupFileExtension = "backup";
    overwriteBackup = true;
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit user gitName gitEmail; };
    users.${user} = import ./home-manager.nix;
  };

  services = {
    # bspwm as the session you land in; every other enabled session (Plasma 6, XFCE)
    # stays selectable in the greeter.
    displayManager.defaultSession = "none+bspwm";

    xserver = {
      enable = true;

      # LightDM lives under services.xserver.displayManager in current nixpkgs
      # (services.displayManager.* is only where sddm/gdm moved to).
      displayManager.lightdm = {
        enable = true;
        greeters.slick.enable = true;
        background = ./config/login-wallpaper.png;
      };

      # Tiling window manager
      windowManager.bspwm.enable = true;

      xkb = {
        # Turn Caps Lock into Ctrl
        layout = "us";
        options = "ctrl:nocaps";
      };
    };

    # Better support for general peripherals
    libinput.enable = true;

    # Picom, the window compositor with the rounded corners / blur / animations
    picom = {
      enable = true;
      settings = {
        animations = true;
        animation-stiffness = 300.0;
        animation-dampening = 35.0;
        animation-clamping = false;
        animation-mass = 1;
        animation-for-workspace-switch-in = "auto";
        animation-for-workspace-switch-out = "auto";
        animation-for-open-window = "slide-down";
        animation-for-menu-window = "none";
        animation-for-transient-window = "slide-down";
        corner-radius = 12;
        rounded-corners-exclude = [
          "class_i = 'polybar'"
          "class_g = 'i3lock'"
        ];
        round-borders = 3;
        round-borders-exclude = [];
        round-borders-rule = [];
        shadow = true;
        shadow-radius = 8;
        shadow-opacity = 0.4;
        shadow-offset-x = -8;
        shadow-offset-y = -8;
        fading = false;
        inactive-opacity = 0.8;
        frame-opacity = 0.7;
        inactive-opacity-override = false;
        active-opacity = 1.0;
        focus-exclude = [
        ];

        opacity-rule = [
          "100:class_g = 'i3lock'"
          "60:class_g = 'Dunst'"
          "100:class_g = 'Alacritty' && focused"
          "90:class_g = 'Alacritty' && !focused"
        ];

        blur-kern = "3x3box";
        blur = {
          method = "kernel";
          strength = 8;
          background = false;
          background-frame = false;
          background-fixed = false;
          kern = "3x3box";
        };

        shadow-exclude = [
          "class_g = 'Dunst'"
        ];

        blur-background-exclude = [
          "class_g = 'Dunst'"
        ];

        backend = "glx";
        vsync = false;
        mark-wmwin-focused = true;
        mark-ovredir-focused = true;
        detect-rounded-corners = true;
        detect-client-opacity = false;
        detect-transient = true;
        detect-client-leader = true;
        use-damage = true;
        log-level = "info";

        wintypes = {
          normal = { fade = true; shadow = false; };
          tooltip = { fade = true; shadow = false; opacity = 0.75; focus = true; full-shadow = false; };
          dock = { shadow = false; };
          dnd = { shadow = false; };
          popup_menu = { opacity = 1.0; };
          dropdown_menu = { opacity = 1.0; };
        };
      };
    };

    gvfs.enable = true; # Mount, trash, and other functionalities
    tumbler.enable = true; # Thumbnail support for images
  };

  programs = {
    # The template also enables programs.gnupg.agent here. It is left out deliberately:
    # this host has both Plasma 6 and XFCE enabled, and in current nixpkgs those two
    # desktop managers each `mkDefault` programs.gnupg.agent.pinentryPackage
    # (pinentry-qt vs pinentry-gnome3), so enabling the agent errors out with
    # "defined multiple times while it's expected to be unique". If you want it, pin it:
    #
    #   programs.gnupg.agent = {
    #     enable = true;
    #     pinentryPackage = lib.mkForce pkgs.pinentry-qt;
    #   };

    # Needed for anything GTK related
    dconf.enable = true;

    # The shell the home-manager config below configures
    zsh.enable = true;
  };

  # Video support (the laptop's GPU)
  hardware.graphics.enable = true;

  # Don't require a password to reboot (as in the starter template)
  security.sudo.extraRules = [{
    commands = [
      {
        command = "${pkgs.systemd}/bin/reboot";
        options = [ "NOPASSWD" ];
      }
    ];
    groups = [ "wheel" ];
  }];

  fonts.packages = with pkgs; [
    dejavu_fonts
    emacs-all-the-icons-fonts
    feather-font # from overlay
    jetbrains-mono
    font-awesome
    noto-fonts
    noto-fonts-color-emoji
  ];

  users.users.${user} = {
    # The desktop's shell (the host's own config adds the rest of the groups)
    shell = pkgs.zsh;
  };
}
