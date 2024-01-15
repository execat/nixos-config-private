# NixOS Config

## On clean install

1. Install Nix as per the instructions on the Determinate installer: [link](https://determinate.systems/posts/determinate-nix-installer)
   ```
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```
2. Install command line tools: `xcode-select --install`
3. Find the required SSH file for Github to make sure this repo is accessible (Ignore if repo is public)
   Test with `ssh -T git@github.com`
4. Run `bin/build` or the specific build script like `bin/darwin-build`

## To update

Go to `flake.nix` and update the inputs:

```
url = "github:nixos/nixpkgs?rev=eabe8d3eface69f5bb16c18f8662a702f50c20d5";
```

The revision could be from this link: https://github.com/NixOS/nixpkgs/tree/nixpkgs-unstable
or any other branch (`nixos-unstable` or any other release)
