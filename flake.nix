{
  description = "Starter Configuration with secrets for MacOS and NixOS";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    home-manager.url = "github:nix-community/home-manager";
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, darwin, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, home-manager, nixpkgs, disko, agenix } @inputs:
    let
      user = "atm";
      gitName = "Anuj More";
      gitEmail = "anujmorex+nixos@gmail.com";
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs (linuxSystems ++ darwinSystems) f;
      devShell = system: let pkgs = nixpkgs.legacyPackages.${system}; in {
        default = with pkgs; mkShell {
          nativeBuildInputs = with pkgs; [ bashInteractive git age age-plugin-yubikey ];
          shellHook = with pkgs; ''
            export EDITOR=vim
          '';
        };
      };
      mkApp = scriptName: system: {
        type = "app";
        program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
          #!/usr/bin/env bash
          PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
          echo "Running ${scriptName} for ${system}"
          exec ${self}/apps/${system}/${scriptName}
        '')}/bin/${scriptName}";
      };
      # Only names with a script at apps/<system>/<name> are declared: mkApp's wrapper execs
      # ${self}/apps/${system}/${scriptName}, so a declaration without a file is a broken app.
      mkLinuxApps = system: {
        "apply" = mkApp "apply" system;
        "build-switch" = mkApp "build-switch" system;
        "clean" = mkApp "clean" system;
      };
      mkDarwinApps = system: {
        "apply" = mkApp "apply" system;
        "build" = mkApp "build" system;
        "build-switch" = mkApp "build-switch" system;
        "clean" = mkApp "clean" system;
      };

      # The real laptop (see hosts/nixos/mokpo/README.md). It manages the actual LUKS
      # containers and filesystems itself, so it takes neither the disko module nor the
      # home-manager module: disko would replace its fileSystems with a placeholder disk.
      mokpoSystem = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs // { inherit user gitName gitEmail inputs; };
        modules = [ ./hosts/nixos/mokpo ];
      };

      # The upstream starter host (bspwm/lightdm/polybar + disko + home-manager, placeholder
      # disk and user). It describes no real filesystem without disko, so it is only useful on
      # a machine you are about to wipe and install with disko.
      starterSystem = system: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = inputs // { inherit user gitName gitEmail inputs; };
        modules = [
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit user gitName gitEmail; };
              users.${user} = import ./modules/nixos/home-manager.nix;
            };
          }
          ./hosts/nixos
        ];
      };
    in
    {
      devShells = forAllSystems devShell;
      apps = nixpkgs.lib.genAttrs linuxSystems mkLinuxApps // nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;

      darwinConfigurations = nixpkgs.lib.genAttrs darwinSystems (system:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = inputs // { inherit user gitName gitEmail inputs; };
          modules = [
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                inherit user;
                enable = true;
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                  "homebrew/homebrew-bundle" = homebrew-bundle;
                };
                mutableTaps = false;
                autoMigrate = true;
              };
            }
            ./hosts/darwin
          ];
        }
      );

      nixosConfigurations = {
        # `mokpo` and `x86_64-linux` are the same system: this laptop. The platform name is an
        # alias so that a bare `nixos-rebuild switch --flake .` / `nix run .#build-switch` --
        # which targets the platform host -- can only ever pick a configuration that boots
        # this machine. Anything that reformats or wrong-disks it lives under other names.
        mokpo = mokpoSystem;
        x86_64-linux = mokpoSystem;

        # The stock starter host, kept for fresh installs only (needs disko + a real disk).
        aarch64-linux = starterSystem "aarch64-linux";
        starter = starterSystem "x86_64-linux";
      };
  };
}
