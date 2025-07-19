{ config, inputs, pkgs, agenix, lib, ... }:

let user = "atm";
    keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p" ]; in
{
  imports = [
    ./secrets.nix
    ./disk-config.nix
    ../shared
    ../shared/cachix
    agenix.nixosModules.default
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 42;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-5301882c-c8ae-4412-8ea9-b8196fe0dad3".device = "/dev/disk/by-uuid/5301882c-c8ae-4412-8ea9-b8196fe0dad3";
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Set your time zone.
  time.timeZone = "Asia/Singapore";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.hostName = "ningbo"; # Define your hostname.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_SG.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_SG.UTF-8";
    LC_IDENTIFICATION = "en_SG.UTF-8";
    LC_MEASUREMENT = "en_SG.UTF-8";
    LC_MONETARY = "en_SG.UTF-8";
    LC_NAME = "en_SG.UTF-8";
    LC_NUMERIC = "en_SG.UTF-8";
    LC_PAPER = "en_SG.UTF-8";
    LC_TELEPHONE = "en_SG.UTF-8";
    LC_TIME = "en_SG.UTF-8";
  };

  # Turn on flag for proprietary software
  nix = {
    nixPath = [ "nixos-config=/home/${user}/.local/share/src/nixos-config:/etc/nixos" ];
    settings.allowed-users = [ "${user}" ];
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
   };

  # Manages keys and such
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = lib.mkForce pkgs.pinentry-qt;
  };

  # Needed for anything GTK related
  programs.dconf.enable = true;

  # Uncomment these for AMD GPU
  # boot.initrd.kernelModules = [ "amdgpu" ];
  # services.xserver.videoDrivers = [ "amdgpu" ];
  services.xserver.videoDrivers = [ "intel" ];

    # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver = {
    enable = true;
    windowManager.awesome = {
      enable = true;
      luaModules = with pkgs.luaPackages; [
        luarocks
        awesome-wm-widgets
      ];
    };
  };

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Change this in 25.11 release
  services.desktopManager.gnome.enable = true;
  services.xserver.desktopManager.xfce.enable = true;

  programs = {
    hyprland = {
      # Install the packages from nixpkgs
      enable = true;
      # Whether to enable XWayland
      xwayland.enable = true;
    };
  };

  programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";

  # Enable CUPS to print documents
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.brlaser ]; # Brother printer driver

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Video support
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  # Enable Xbox support
  # hardware.xone.enable = true;

  # Crypto wallet support
  hardware.ledger.enable = true;

  # Better support for general peripherals
  services.libinput.enable = true;
  boot.kernelModules = [ "uinput" ];

  # Add docker daemon
  virtualisation.docker.enable = true;
  virtualisation.docker.logDriver = "json-file";

  # It's me, it's you, it's everyone
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "docker"
      "networkmanager"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = keys;
  };

  # Root user
  users.users.root = {
    openssh.authorizedKeys.keys = keys;
  };

  # Don't require password for users in `wheel` group for these commands
  security.sudo.wheelNeedsPassword = false;

  # Let's be able to SSH into this machine
  services.openssh.enable = true;

  # My shell
  programs.zsh.enable = true;
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # My editor runs as a daemon
  services.emacs = {
    enable = true;
  };

  fonts.packages = with pkgs; [
    dejavu_fonts
    emacs-all-the-icons-fonts
    jetbrains-mono
    font-awesome
    noto-fonts
    noto-fonts-emoji
  ];

  environment.systemPackages = with pkgs; [
    agenix.packages."${pkgs.system}".default # "x86_64-linux"
    gitAndTools.gitFull
    inetutils
    curl
    vim
    wget
  ];

  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
