#!/bin/bash
# Install the Flatpak applications. Distro-independent; needs flatpak installed.
set -euo pipefail

APPS=(
  com.github.tchx84.Flatseal
  it.mijorus.gearlever
  org.onlyoffice.desktopeditors
  org.videolan.VLC
  org.nickvision.tubeconverter
  net.nokyan.Resources
  md.obsidian.Obsidian
  fr.handbrake.ghb
  com.github.xournalpp.xournalpp
  org.mozilla.thunderbird
  org.telegram.desktop
  org.gnome.Papers
)

sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo flatpak install -y flathub "${APPS[@]}"
echo "done"
