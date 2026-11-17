#!/bin/bash
# Stage 1: install a minimal Arch Linux into /mnt. Run as root from the live ISO.
#
# Prerequisites: booted in UEFI mode, partitions created, formatted and mounted
# (see README.md), the root filesystem on /mnt and the EFI partition on /mnt/boot/efi.
#
# Usage:
#   ./install-base.sh [--cpu amd|intel] [--tz Europe/Berlin] [--hostname NAME]
#                     [--user NAME] [--keymap de-latin1]
#
# Anything not given as a flag is detected (CPU), defaulted (keymap) or asked for.
# When it is done, reboot into the new system, log in on a TTY and continue with
# desktop-setup.sh.
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

CPU=""
TIMEZONE=""
NEW_HOSTNAME=""
NEW_USER=""
KEYMAP="de-latin1"

while [ $# -gt 0 ]; do
  case "$1" in
    --cpu)      CPU="${2:?--cpu needs a value}"; shift 2 ;;
    --tz)       TIMEZONE="${2:?--tz needs a value}"; shift 2 ;;
    --hostname) NEW_HOSTNAME="${2:?--hostname needs a value}"; shift 2 ;;
    --user)     NEW_USER="${2:?--user needs a value}"; shift 2 ;;
    --keymap)   KEYMAP="${2:?--keymap needs a value}"; shift 2 ;;
    -h|--help)  sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)          die "unknown option: $1" ;;
  esac
done

require_root
[ -d /sys/firmware/efi ] || die "not booted in UEFI mode; this installer sets up GRUB for UEFI."
mountpoint -q /mnt          || die "/mnt is not a mount point. Mount your partitions first (see README.md)."
mountpoint -q /mnt/boot/efi || die "/mnt/boot/efi is not mounted. Mount the EFI partition there first."

# CPU: detect from /proc/cpuinfo unless given.
if [ -z "$CPU" ]; then
  case "$(grep -m1 vendor_id /proc/cpuinfo)" in
    *AuthenticAMD*) CPU="amd" ;;
    *GenuineIntel*) CPU="intel" ;;
    *) read -r -p "CPU vendor (amd or intel): " CPU ;;
  esac
  echo "CPU: $CPU"
fi
case "$CPU" in amd|intel) ;; *) die "--cpu must be 'amd' or 'intel', got '$CPU'." ;; esac

if [ -z "$TIMEZONE" ]; then
  read -r -p "Time zone (e.g. Europe/Berlin): " TIMEZONE
fi
[ -f "/usr/share/zoneinfo/$TIMEZONE" ] || die "unknown time zone '$TIMEZONE'."

if [ -z "$NEW_HOSTNAME" ]; then
  read -r -p "Hostname: " NEW_HOSTNAME
fi
[[ "$NEW_HOSTNAME" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$ ]] || die "invalid hostname '$NEW_HOSTNAME'."

if [ -z "$NEW_USER" ]; then
  read -r -p "User name: " NEW_USER
fi
[[ "$NEW_USER" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "invalid user name '$NEW_USER'."

echo "Updating mirrors"
reflector --country "$MIRROR_COUNTRIES" --age 12 --protocol https --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

echo "Installing the base system into /mnt"
load_packages PKGS "$ARCH_DIR/packages/base.txt"
[ "${#PKGS[@]}" -gt 0 ] || die "packages/base.txt is empty."
pacstrap -K /mnt "${PKGS[@]}" "$CPU-ucode"

echo "Generating fstab"
genfstab -U /mnt > /mnt/etc/fstab

# Put the repository on the new system so the later stages are available after reboot.
echo "Copying the repository to /mnt/root/miscellaneous"
rm -rf /mnt/root/miscellaneous
cp -a "$REPO_ROOT" /mnt/root/miscellaneous

echo "Configuring the system (chroot)"
arch-chroot /mnt env \
  TIMEZONE="$TIMEZONE" \
  NEW_HOSTNAME="$NEW_HOSTNAME" \
  NEW_USER="$NEW_USER" \
  KEYMAP="$KEYMAP" \
  bash /root/miscellaneous/arch/chroot.sh

echo "Unmounting /mnt"
umount -R /mnt

cat <<EOF

Base installation finished. Next:
  1. reboot and remove the installation medium
  2. log in as $NEW_USER on the console
     (Wi-Fi only machine? connect first: nmcli device wifi connect <SSID> --ask)
  3. cd ~/miscellaneous/arch && ./desktop-setup.sh
     then ./tweaks.sh and ./apps-setup.sh
EOF
