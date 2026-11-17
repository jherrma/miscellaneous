#!/bin/bash
# Stage 3: system tweaks. Run as your normal user on the booted system (uses sudo).
#
#   * mirror refresh via reflector.timer
#   * pacman hook that backs up /boot before kernel changes
#   * zram swap (zram-generator) with sysctl tuning, replacing the AUR 'zramd'
#   * journald size limit
#   * disable services a desktop doesn't need (wait-online, auditd, acpid)
#   * ufw firewall: deny incoming, allow outgoing
#
# This has to run on the booted system: a chroot has no netfilter, so ufw can't
# be enabled there. Idempotent.
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_user

# --- Tuning knobs (same values as fedora/setup-zram.sh) ----------------------
ZRAM_SIZE="min(ram, 8192)"
# zstd level 15 (range 1-22, kernel default 3): better ratio, costs CPU on swap-out.
ZRAM_ALGORITHM="zstd(level=15)"
SWAPPINESS=120
PAGE_CLUSTER=0
JOURNAL_MAX="200M"
# -----------------------------------------------------------------------------

sudo pacman -S --needed --noconfirm reflector rsync zram-generator ufw

echo "Mirrors: reflector.timer"
sudo tee /etc/xdg/reflector/reflector.conf >/dev/null <<EOF
--country $MIRROR_COUNTRIES
--age 12
--protocol https
--latest 5
--sort rate
--save /etc/pacman.d/mirrorlist
EOF
sudo systemctl enable reflector.timer

echo "Pacman hook: back up /boot before kernel changes"
sudo mkdir -p /etc/pacman.d/hooks
sudo tee /etc/pacman.d/hooks/50-bootbackup.hook >/dev/null <<'EOF'
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Path
Target = usr/lib/modules/*/vmlinuz

[Action]
Depends = rsync
Description = Backing up /boot...
When = PreTransaction
Exec = /usr/bin/rsync -a --delete /boot /boot-backup
EOF

echo "zram"
if pacman -Q zramd >/dev/null 2>&1; then
  echo "Replacing the AUR package zramd"
  sudo systemctl disable --now zramd.service || true
  sudo pacman -Rns --noconfirm zramd
fi
sudo tee /etc/systemd/zram-generator.conf >/dev/null <<EOF
[zram0]
zram-size = $ZRAM_SIZE
compression-algorithm = $ZRAM_ALGORITHM
EOF
sudo tee /etc/sysctl.d/99-zram-tuning.conf >/dev/null <<EOF
# Tuned for zram swap: swapping to compressed RAM is cheap, and readahead buys
# nothing when the backing device is memory.
vm.swappiness = $SWAPPINESS
vm.page-cluster = $PAGE_CLUSTER
EOF
sudo sysctl --system >/dev/null
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service || \
  echo "zram0 could not be (re)started right now; it will be set up on the next boot."

echo "journald: limit to $JOURNAL_MAX"
sudo mkdir -p /etc/systemd/journald.conf.d
sudo tee /etc/systemd/journald.conf.d/size.conf >/dev/null <<EOF
[Journal]
SystemMaxUse=$JOURNAL_MAX
EOF
sudo systemctl restart systemd-journald

echo "Disabling services a desktop doesn't need"
# wait-online only delays units ordered after network-online.target; nothing here needs that.
# auditd/acpid are not installed by this setup, so they are only disabled if present.
sudo systemctl disable NetworkManager-wait-online.service
for svc in auditd.service acpid.service; do
  if systemctl list-unit-files "$svc" --no-legend | grep -q .; then
    sudo systemctl disable --now "$svc"
  fi
done

echo "Firewall: ufw"
sudo ufw default deny incoming
sudo ufw default allow outgoing
# Don't lock yourself out of a machine that is administered over SSH.
if systemctl is-enabled --quiet sshd.service 2>/dev/null; then
  echo "sshd is enabled: allowing SSH (rate limited)"
  sudo ufw limit ssh
fi
sudo ufw --force enable
sudo systemctl enable ufw.service

echo
swapon --show
sudo ufw status verbose
