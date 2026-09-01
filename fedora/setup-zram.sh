#!/bin/bash
# Set up and tune zram swap on Fedora.
#
# Fedora Workstation already enables zram out of the box via the
# zram-generator-defaults package, but it ships no zram-specific tuning: it
# keeps the disk-era vm.swappiness=60 / vm.page-cluster=3 defaults and the
# lzo-rle compressor. This script fixes that, and removes the unrelated legacy
# 'zram' package (zram-swap.service) if it is installed, since having both
# around is a reliable source of "is my zram even running?" confusion.
#
# Idempotent - safe to re-run.
#
# Usage:
#   ./setup-zram.sh           # show the planned changes, then ask
#   ./setup-zram.sh --force   # apply without asking
set -euo pipefail

# --- Tuning knobs ------------------------------------------------------------
# Fedora's default; ram/2 is the other common choice. See zram-generator.conf(5).
ZRAM_SIZE="min(ram, 8192)"
# zstd compresses noticeably better than the lzo-rle default for a little CPU.
ZRAM_ALGORITHM="zstd"
# zram is RAM-fast, so swapping out early is cheap. Kernel max is 200.
SWAPPINESS=180
# Swap readahead is wasted work when the "disk" is memory.
PAGE_CLUSTER=0
# -----------------------------------------------------------------------------

ZRAM_CONF="/etc/systemd/zram-generator.conf"
SYSCTL_CONF="/etc/sysctl.d/99-zram-tuning.conf"

FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    -h|--help)
      sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

if [ ! -f /etc/fedora-release ]; then
  echo "This script targets Fedora. /etc/fedora-release not found." >&2
  exit 1
fi

# Work out what actually needs doing, so a re-run can report "nothing to do".
NEED_GENERATOR=0
NEED_REMOVE_LEGACY=0
NEED_ZRAM_CONF=0
NEED_SYSCTL=0

rpm -q zram-generator-defaults >/dev/null 2>&1 || NEED_GENERATOR=1
rpm -q zram >/dev/null 2>&1 && NEED_REMOVE_LEGACY=1

read -r -d '' DESIRED_ZRAM_CONF <<CONF || true
# Managed by miscellaneous/fedora/setup-zram.sh
[zram0]
zram-size = $ZRAM_SIZE
compression-algorithm = $ZRAM_ALGORITHM
CONF

read -r -d '' DESIRED_SYSCTL <<CONF || true
# Managed by miscellaneous/fedora/setup-zram.sh
# Tuned for zram swap: swapping to compressed RAM is cheap, and readahead
# buys nothing when the backing device is memory.
vm.swappiness = $SWAPPINESS
vm.page-cluster = $PAGE_CLUSTER
CONF

[ -f "$ZRAM_CONF" ] && [ "$(cat "$ZRAM_CONF")" = "$DESIRED_ZRAM_CONF" ] || NEED_ZRAM_CONF=1
[ -f "$SYSCTL_CONF" ] && [ "$(cat "$SYSCTL_CONF")" = "$DESIRED_SYSCTL" ] || NEED_SYSCTL=1

TOTAL=$((NEED_GENERATOR + NEED_REMOVE_LEGACY + NEED_ZRAM_CONF + NEED_SYSCTL))
if [ "$TOTAL" -eq 0 ]; then
  echo "zram is already set up and tuned - nothing to do."
  echo
  swapon --show
  exit 0
fi

echo "zram setup on Fedora - planned changes:"
[ "$NEED_GENERATOR" -eq 1 ]     && echo "  * install zram-generator-defaults (zram is not enabled yet)"
[ "$NEED_REMOVE_LEGACY" -eq 1 ] && echo "  * remove the legacy 'zram' package (its zram-swap.service is unused)"
[ "$NEED_ZRAM_CONF" -eq 1 ]     && echo "  * write $ZRAM_CONF (size $ZRAM_SIZE, compression $ZRAM_ALGORITHM)"
[ "$NEED_SYSCTL" -eq 1 ]        && echo "  * write $SYSCTL_CONF (vm.swappiness=$SWAPPINESS, vm.page-cluster=$PAGE_CLUSTER)"
echo

if [ "$FORCE" -eq 0 ]; then
  read -r -p "Continue? [y/N] " reply
  case "$reply" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "Aborted."; exit 1 ;;
  esac
  echo
fi

if [ "$NEED_GENERATOR" -eq 1 ]; then
  echo "Installing zram-generator-defaults"
  sudo dnf install -y zram-generator-defaults
fi

if [ "$NEED_REMOVE_LEGACY" -eq 1 ]; then
  echo "Removing the legacy 'zram' package"
  # Only ever disabled, but make sure before pulling it out.
  sudo systemctl disable --now zram-swap.service >/dev/null 2>&1 || true
  sudo dnf remove -y zram
fi

if [ "$NEED_ZRAM_CONF" -eq 1 ]; then
  echo "Writing $ZRAM_CONF"
  printf '%s\n' "$DESIRED_ZRAM_CONF" | sudo tee "$ZRAM_CONF" >/dev/null
fi

if [ "$NEED_SYSCTL" -eq 1 ]; then
  echo "Writing $SYSCTL_CONF"
  printf '%s\n' "$DESIRED_SYSCTL" | sudo tee "$SYSCTL_CONF" >/dev/null
  sudo sysctl --system >/dev/null
  echo "Applied: vm.swappiness=$(sysctl -n vm.swappiness) vm.page-cluster=$(sysctl -n vm.page-cluster)"
fi

# Re-creating the device means swapping off first, which needs enough free RAM
# to take back whatever is currently compressed in there. Only do it when the
# device is empty; otherwise leave it for the next boot.
if [ "$NEED_ZRAM_CONF" -eq 1 ]; then
  USED="$(swapon --show=NAME,USED --bytes --noheadings 2>/dev/null | awk '$1=="/dev/zram0"{print $2}')"
  if [ -z "${USED:-}" ]; then
    echo "Starting zram device"
    sudo systemctl start systemd-zram-setup@zram0.service
  elif [ "$USED" -eq 0 ]; then
    echo "Re-creating /dev/zram0 with the new settings"
    sudo systemctl restart dev-zram0.swap
  else
    echo "/dev/zram0 currently holds $USED bytes; leaving it alone."
    echo "The new compression algorithm takes effect after the next reboot."
  fi
fi

echo
echo "Current state:"
swapon --show
command -v zramctl >/dev/null 2>&1 && zramctl
