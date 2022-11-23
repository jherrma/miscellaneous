#!/bin/bash
sudo pacman -S --noconfirm nix

mkdir -p ~/.config/nixpkgs
echo "
{
    allowUnfree = true;
    segger-jlink.acceptLicense = true;
}
" >> ~/.config/nixpkgs/config.nix

nix-channel --add https://nixos.org/channels/nixpkgs-unstable
nix-channel --update
