{ config, inputs, pkgs, lib, agenix, ... }:

let
  user = "atm";
  keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p" ];
  sharedFiles = import ../shared/files.nix { inherit config pkgs; };
  additionalFiles = import ./files.nix { inherit config pkgs; };
in
{
  imports = [
    ../shared
  ];

  #nix = {
  #  settings.allowed-users = [ "${user}" ];
  #  package = pkgs.nixUnstable;
  #  extraOptions = ''
  #    experimental-features = nix-command flakes
  #  '';
  #};

  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";
    packages = pkgs.callPackage ./packages.nix {};
    activation = {};
    stateVersion = "21.05";
    file = lib.mkMerge [
      sharedFiles
      additionalFiles
    ];
  };

  # Let's be able to SSH into this machine
  # services.openssh.enable = true;

  programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib; };

  # My editor runs as a dasemon
  services.emacs = {
    enable = true;
    client = {
      enable = true;
      arguments = ["-c"];
    };
  };
}
