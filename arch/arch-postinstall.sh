#!/bin/bash
echo "Installing Paru"
cd Downloads
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..
rm -rf paru
cd
echo "Installing Paru done\n\n"

echo "Installing zramd"
paru -S --noconfirm zramd
sudo systemctl enable --now zramd.service




