# Arch

For Arch setup, some things have to be done manually:

1. Install fonts
    ```
        sudo pacman -S powerline-fonts nerd-fonts
    ```
    And set this font on the terminal. Make sure all icons look okay.
2. Set zsh
    ```
        echo $HOME/.nix-profile/bin/zsh | sudo tee -a /etc/shells
        chsh -s ~/.nix-profile/bin/zsh
    ```
3. Install gparted
    ```
        sudo pacman -S gparted
    ```