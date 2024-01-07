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
