#!/usr/bin/env bash

# Get the latest commit hash from nixpkgs-unstable
latest_commit=$(curl -s https://api.github.com/repos/NixOS/nixpkgs/commits/nixpkgs-unstable | jq -r '.sha')

# Get current date in the format used in the file
current_date=$(date "+%dth %b %Y")

# Update the flake.nix file
sed -i.bak -e "s|# This revision: .*|# This revision: $current_date|" \
           -e "s|url = \"github:nixos/nixpkgs?rev=.*\"|url = \"github:nixos/nixpkgs?rev=$latest_commit\"|" \
           flake.nix

# Remove backup file
rm flake.nix.bak

echo "Updated nixpkgs to commit: $latest_commit" 