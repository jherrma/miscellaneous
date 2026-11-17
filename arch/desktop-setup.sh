#!/bin/bash
# Stage 2: turn the minimal installation into a KDE Plasma (Wayland) desktop.
# Run as your normal user on the installed system (it uses sudo).
#
# Installs packages/desktop.txt: Plasma with Plasma Login Manager, the PipeWire
# audio stack, Wayland support, the KDE apps, fonts and printing. Idempotent.
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_user

echo "Installing the desktop packages"
pacman_install "$ARCH_DIR/packages/desktop.txt"

echo "Enabling Plasma Login Manager and printing"
# Only one display manager can own display-manager.service. When migrating from
# GNOME or KDE-with-SDDM, disable the old one first; --force below replaces the link.
for dm in gdm sddm lightdm; do
  if systemctl is-enabled --quiet "$dm.service" 2>/dev/null; then
    echo "Disabling $dm"
    sudo systemctl disable "$dm.service"
  fi
done
sudo systemctl enable --force plasmalogin.service
sudo systemctl enable cups.socket

echo "Keyboard layout for the graphical session and login screen"
# --no-convert: leave the console keymap from /etc/vconsole.conf alone.
sudo localectl --no-convert set-x11-keymap de

xdg-user-dirs-update

echo
echo "Desktop installed. Reboot to land in the Plasma Login Manager."
