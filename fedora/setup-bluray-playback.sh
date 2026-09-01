#!/bin/bash
# source: https://negativo17.org/bluray-playback-and-ripping-on-fedora-aacs-bd-bd-j/
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf install -y libaacs libbdplus libbluray-utils vlc
mkdir -p ~/.config/aacs
# get KEYDB.cfg file
wget -c http://fvonline-db.bplaced.net/fv_download.php?lang=eng -O ~/Downloads
unzip ~/Downloads/keydb_eng.zip
mv ~/Downloads/keydb.cfg ~/.config/aacs/KEYDB.cfg  