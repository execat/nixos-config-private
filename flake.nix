{
  description = "Starter Configuration for NixOS and MacOS";

  inputs = {
    nixpkgs = {
      # This revision: 6th Mar 2024
      # From branch: nixpkgs-unstable
      url = "github:nixos/nixpkgs?rev=9052a2666b6292fced270a2264776c203442fbe1";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
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
  } @ inputs: let
    user = "anuj.more";
    systems = ["x86_64-linux" "aarch64-darwin"];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    devShell = system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = with pkgs;
        mkShell {
          nativeBuildInputs = with pkgs; [bashInteractive git age age-plugin-yubikey];
          shellHook = with pkgs; ''
            export EDITOR=vim
          '';
        };
    };
  in {
    devShells = forAllSystems devShell;

    darwinConfigurations = let
      user = "anuj.more";
    in {
      macos = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = inputs;
        modules = [
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            nix-homebrew = {
              enable = true;
              user = "${user}";
              autoMigrate = true;
            };
          }
          ./darwin
        ];
      };
    };
  };
}
