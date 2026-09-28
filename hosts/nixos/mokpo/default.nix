# Host: mokpo — port of this machine's /etc/nixos/configuration.nix into the repo.
#
# Boot-critical settings (LUKS devices, filesystems, swap, kernel modules, EFI bootloader
# settings) live in ./hardware-configuration.nix, a verbatim copy of
# /etc/nixos/hardware-configuration.nix.
#
# This host deliberately does NOT import modules/nixos/disk-config.nix (disko): the disk is
# already partitioned and formatted, so disko must not manage it. Importing it would replace
# fileSystems with the template's placeholder disk device and the machine would not boot.
#
# Deploy:
#   sudo nixos-rebuild switch --flake .#mokpo
#   nix run .#build-switch -- --host mokpo
#
# Secrets: ./secrets.nix (agenix), encrypted blobs in ../../../secrets/, recipients in
# ../../../agenix-rules.nix, workflow in ../../../secrets/README.md.

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # agenix: secrets are decrypted at activation with this host's own OpenSSH host keys.
      # See ./secrets.nix, ../../../agenix-rules.nix and ../../../secrets/README.md.
      inputs.agenix.nixosModules.default
      ./secrets.nix

      # The starter template's desktop (bspwm + lightdm/slick + polybar + rofi + picom +
      # dunst, home-manager-managed dotfiles). It touches no disks: the disko module
      # (modules/nixos/disk-config.nix) is deliberately not part of it. Disable it by
      # deleting this import if you only want the KDE/XFCE desktop below.
      ../../../modules/nixos/desktop.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.luks.devices."luks-a7d4c564-9abe-4be7-946e-2ddbd385338e".device = "/dev/disk/by-uuid/a7d4c564-9abe-4be7-946e-2ddbd385338e";

  networking.hostName = "mokpo"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Singapore";

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

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment and XFCE, as extra sessions.
  # SDDM is off: the display manager is lightdm + slick greeter, enabled by
  # ../../../modules/nixos/desktop.nix, which is what makes bspwm the default session.
  # Both Plasma and XFCE still show up in the greeter's session list.
  services.displayManager.sddm.enable = false;
  services.desktopManager.plasma6.enable = true;
  services.xserver.desktopManager = {
    xterm.enable = false;
    xfce.enable = true;
  };

  # Keep Baloo's content extractor independent of any X/Wayland display.
  #
  # baloo_file_extractor is a Qt GUI application (it constructs a QGuiApplication), so Qt
  # loads a platform plugin for it, and Qt prefers xcb whenever DISPLAY is set. When the
  # baloo_file daemon outlives the session it was started in -- e.g. an X11/XFCE session
  # whose X server dies and whose logout never finishes, leaving the daemon reparented to
  # PID 1 still holding DISPLAY=:0.0 -- every extractor it spawns fails with "could not
  # connect to display :0.0", aborts on SIGABRT, and drkonqi raises a "Service Crash"
  # dialog for each one. The extractor renders nothing, so pin it to the offscreen platform
  # and it no longer cares about DISPLAY at all.
  #
  # kde-baloo.service comes from the baloo package (share/systemd/user), not from a NixOS
  # unit, so this has to be a drop-in: a full unit here would shadow the vendor unit in
  # /etc/systemd/user and the daemon would lose its ExecStart= and BusName=.
  systemd.user.services.kde-baloo = {
    overrideStrategy = "asDropin";
    environment.QT_QPA_PLATFORM = "offscreen";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;
  };
  security.sudo.wheelNeedsPassword = false;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."atm" = {
    isNormalUser = true;
    description = "atm";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    wget
    emacs
    mercurialFull
    git
    jujutsu
    vim
    uv
    file
    coreutils
    transmission_4-gtk
    direnv
    zellij
    ghostty
    bat
    tree
    tokei
    sqlitebrowser
    vlc

    # The agenix CLI, for editing the secrets in ../../../secrets/ (`agenix -e`). The
    # activation-time decryption in ./secrets.nix does not need it. As on the starter host.
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
