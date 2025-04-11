{ agenix, config, pkgs, ... }:

let user = "atm"; in
{

  imports = [
    ./secrets.nix
    ./home-manager.nix
    ../shared
    ../shared/cachix
     agenix.darwinModules.default
  ];

  security.pam.services.sudo_local.touchIdAuth = true;

  # Setup user, packages, programs
  nix = {
    package = pkgs.nixVersions.latest;
    settings.trusted-users = [ "@admin" "${user}" ];
    enable = true;

    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };

    # Turn this on to make command line easier
    extraOptions = ''
      experimental-features = nix-command flakes auto-allocate-uids
    '';
  };

  # Turn off NIX_PATH warnings now that we're using flakes
  system.checks.verifyNixPath = false;

  # Load configuration that is shared across systems
  environment.systemPackages = with pkgs; [
    agenix.packages."${pkgs.system}".default
  ] ++ (import ../shared/packages.nix { inherit pkgs; });

  networking = {
    hostName = "goyang";
    computerName = "goyang";
    localHostName = "goyang";
  };

  system = {
    stateVersion = 4;

    defaults = {
      LaunchServices = {
        LSQuarantine = false;
      };

      menuExtraClock = {
        Show24Hour = true;
      };

      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        AppleShowScrollBars = "Always";
        ApplePressAndHoldEnabled = false;

        # 120, 90, 60, 30, 12, 6, 2
        KeyRepeat = 2;

        # 120, 94, 68, 35, 25, 15
        InitialKeyRepeat = 15;

        AppleFontSmoothing = 1;
        AppleKeyboardUIMode = 3;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        NSTableViewDefaultSizeMode = 1;
        NSTextShowsControlCharacters = true;
        NSWindowResizeTime = 0.001;
        PMPrintingExpandedStateForPrint = true;
        NSAutomaticWindowAnimationsEnabled = false;
        NSScrollAnimationEnabled = false;

        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.swipescrolldirection" = false;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };

      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.0;
        enable-spring-load-actions-on-all-items = true;
        launchanim = false;
        mineffect = "suck";
        minimize-to-application = true;
        mouse-over-hilite-stack = true;
        mru-spaces = false;
        show-process-indicators = true;
        show-recents = false;
        showhidden = true;
        tilesize = 48;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
      };

      finder = {
       _FXShowPosixPathInTitle = true;
        AppleShowAllExtensions = true;
        FXPreferredViewStyle = "clmv";
        FXEnableExtensionChangeWarning = false;
        QuitMenuItem = true;
        # DisableAllAnimations = true;
        # WarnOnEmptyTrash = false;
      };

      smb = {
        NetBIOSName = "goyang";
      };

      trackpad = {
        Clicking = true;
        FirstClickThreshold = 0;
        SecondClickThreshold = 0;
        TrackpadThreeFingerDrag = true;
      };
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };
}
