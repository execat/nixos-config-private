
{
  description = "Starter Configuration for NixOS and MacOS";

  inputs = {
    nixpkgs = {
      # This revision: 26th Sept 02:46
      url = "github:nixos/nixpkgs?rev=e42717254714b9d312d1e4f15332952848fac3eb";
    };
    agenix.url = "github:ryantm/agenix";
    home-manager.url = "github:nix-community/home-manager";
    darwin = {
      url = "github:execat/nix-darwin/master";
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
  };
}
