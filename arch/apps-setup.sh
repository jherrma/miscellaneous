#!/bin/bash
# Stage 4: applications. Run as your normal user on the booted system (uses sudo).
#
#   1. native packages from packages/apps.txt
#   2. paru (AUR helper), then the AUR packages in packages/aur.txt
#   3. snapd setup and the snaps in distro-independent/install-snaps.sh
#   4. Flatpaks via distro-independent/install-flatpaks.sh
#
# Idempotent.
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_user

echo "Installing native applications"
pacman_install "$ARCH_DIR/packages/apps.txt"

if ! command -v paru >/dev/null 2>&1; then
  echo "Installing paru"
  sudo pacman -S --needed --noconfirm base-devel git
  BUILD_DIR="$(mktemp -d)"
  trap 'rm -rf "$BUILD_DIR"' EXIT
  git clone https://aur.archlinux.org/paru.git "$BUILD_DIR/paru"
  (cd "$BUILD_DIR/paru" && makepkg -si --noconfirm)
fi

echo "Installing AUR packages"
load_packages AUR_PKGS "$ARCH_DIR/packages/aur.txt"
if [ "${#AUR_PKGS[@]}" -gt 0 ]; then
  paru -S --needed "${AUR_PKGS[@]}"
fi

if command -v snap >/dev/null 2>&1; then
  echo "Setting up snapd"
  sudo systemctl enable --now snapd.socket
  # Classic snaps expect /snap.
  [ -e /snap ] || sudo ln -s /var/lib/snapd/snap /snap
  # First start downloads and seeds the core snap; wait for it.
  sudo snap wait system seed.loaded
  echo "Installing snaps"
  "$REPO_ROOT/distro-independent/install-snaps.sh"
fi

echo "Installing Flatpaks"
"$REPO_ROOT/distro-independent/install-flatpaks.sh"

echo "Done."
