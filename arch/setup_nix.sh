#!/bin/bash
sudo pacman -S --noconfirm nix

mkdir -p ~/.config/nixpkgs
echo "
{
    allowUnfree = true;
    segger-jlink.acceptLicense = true;
}
" >> ~/.config/nixpkgs/config.nix

sudo systemctl enable nix-daemon.service
sudo systemctl start nix-daemon.service

sudo usermod -aG nix-users $USER

nix-channel --add https://nixos.org/channels/nixpkgs-unstable
nix-channel --update
