#!/bin/bash
# Install the snap applications. Distro-independent; needs snapd running
# (on Arch, arch/apps-setup.sh enables snapd.socket and creates the /snap link).
set -euo pipefail

# Installed with --classic (unconfined, like a regular package).
CLASSIC_SNAPS=(
  code
  flutter
)

for snap_name in "${CLASSIC_SNAPS[@]}"; do
  if snap list "$snap_name" >/dev/null 2>&1; then
    echo "$snap_name is already installed"
  else
    sudo snap install --classic "$snap_name"
  fi
done
echo "done"
