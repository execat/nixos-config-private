{
  description = "Starter Configuration for NixOS and MacOS";

  inputs = {
    nixpkgs = {
      # This revision: 10th May 2025
      # Branch: nixpkgs-unstable: https://github.com/NixOS/nixpkgs/tree/nixpkgs-unstable
      url = "github:nixos/nixpkgs?rev=b3582c75c7f21ce0b429898980eddbbf05c68e55";
    };
    agenix = {
      url = "github:ryantm/agenix";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
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
    secrets = {
      url = "git+ssh://git@github.com/execat/nix-secrets.git"; # Change this!
      flake = false;
    };
  };

  outputs = {
      self,
      darwin,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      home-manager,
      nixpkgs,
      disko,
      agenix,
      secrets
    } @inputs:
    let
      user = "atm";
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
      devShell = system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        default = with pkgs; mkShell {
          nativeBuildInputs = with pkgs; [ bashInteractive git age age-plugin-yubikey ];
          shellHook = with pkgs; ''
          '';
        };
      };
    in
    {

      devShells = forAllSystems devShell;

      darwinConfigurations = let user = "atm"; in {
        macos = darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          specialArgs = inputs;
          modules = [
            nix-homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
            {
              nix-homebrew = {
                enable = true;
                user = "${user}";
                taps = {};
                mutableTaps = true;
                autoMigrate = true;
              };
            }
            ./darwin
          ];
        };
      };

      nixosConfigurations = let user = "atm"; in {
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = inputs;
          modules = [
            ./nixos
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${user} = import ./nixos/home-manager.nix;
            }
          ];
        };
      };

      homeConfigurations = let
        user = "atm";
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        arch = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./arch
          ];
        };
      };
    };
}
