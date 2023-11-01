{ config, pkgs, lib, home-manager, ... }:

let
  user = "anuj.more";
  sharedFiles = import ../shared/files.nix { inherit config pkgs; };
  additionalFiles = import ./files.nix { inherit config pkgs; };
in
{
  imports = [
   ./dock
  ];

  # It me
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
    taps = [
      # "homebrew/core"
      # "homebrew/cask"
      "sourcegraph/src-cli"
      {
        name = "flip/homebrew";
        clone_target = "git@gitlab.myteksi.net:spartan/flip/homebrew.git";
        force_auto_update = true;
      }
    ];
    brews = [
      "src-cli"
      "grab-kit"
      "clang-format"
    ];
    casks = pkgs.callPackage ./casks.nix {};

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    masApps = {
      # "wireguard" = 1451685025;
    };
  };

  # Enable home-manager
  home-manager = {
    useGlobalPkgs = true;
    users.${user} = { pkgs, config, lib, ... }:{
      home.enableNixpkgsReleaseCheck = false;
      home.packages = pkgs.callPackage ./packages.nix {};
      home.file = lib.mkMerge [
        sharedFiles
        additionalFiles
      ];
      home.stateVersion = "21.11";
      programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib; };

      # Marked broken Oct 20, 2022 check later to remove this
      # https://github.com/nix-community/home-manager/issues/3344
      manual.manpages.enable = false;
    };
  };

  # Fully declarative dock using the latest from Nix Store
  local.dock.enable = true;
  local.dock.entries = [
    { path = "${pkgs.alacritty}/Applications/Alacritty.app/"; }
    { path = "/Applications/Firefox.app/"; }
    { path = "/Applications/Google Chrome.app"; }
    { path = "/Applications/Cisco/Cisco AnyConnect Secure Mobility Client.app"; }
    { path = "/Applications/zoom.us.app"; }
    { path = "/Applications/GoLand.app"; }
    { path = "/Applications/UTM.app"; }
    { path = "/Applications/Visual Studio Code.app"; }
    {
      path = "${config.users.users.${user}.home}/Downloads/";
      section = "others";
      options = "--sort name --view grid --display stack";
    }
  ];
}
