#!/bin/bash
# Stage 1b: configure the freshly installed system. Runs INSIDE the chroot and is
# started by install-base.sh via arch-chroot, which passes TIMEZONE, NEW_HOSTNAME,
# NEW_USER and KEYMAP in the environment. Not meant to be run by hand.
set -euo pipefail

: "${TIMEZONE:?TIMEZONE is not set}"
: "${NEW_HOSTNAME:?NEW_HOSTNAME is not set}"
: "${NEW_USER:?NEW_USER is not set}"
KEYMAP="${KEYMAP:-de-latin1}"

echo "Time zone: $TIMEZONE"
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

echo "Locale and keyboard"
sed -i 's/^#\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

echo "Hostname: $NEW_HOSTNAME"
echo "$NEW_HOSTNAME" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1 localhost
::1       localhost
127.0.1.1 $NEW_HOSTNAME.localdomain $NEW_HOSTNAME
EOF

# nss-mdns: resolve *.local names through avahi.
if ! grep -q mdns_minimal /etc/nsswitch.conf; then
  sed -i '/^hosts:/ s/resolve/mdns_minimal [NOTFOUND=return] resolve/' /etc/nsswitch.conf
fi

echo "Initramfs"
mkinitcpio -P

echo "Bootloader (GRUB)"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux
grub-mkconfig -o /boot/grub/grub.cfg

echo "Enabling services"
systemctl enable NetworkManager.service systemd-timesyncd.service avahi-daemon.service \
  bluetooth.service fstrim.timer

echo "Creating user $NEW_USER"
# wheel is the only group needed: it grants sudo (below) and journal access.
# Device access (audio, video, input, ...) is handled per session by systemd-logind,
# so the old audio/video/storage/... groups are neither needed nor desirable.
if ! id "$NEW_USER" >/dev/null 2>&1; then
  useradd -mU -s /bin/zsh -G wheel "$NEW_USER"
fi

# Members of wheel may use sudo. visudo -c refuses to leave a broken file behind.
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel
chmod 440 /etc/sudoers.d/10-wheel
visudo -cf /etc/sudoers.d/10-wheel

# passwd exits non-zero on a typo; retry instead of aborting the whole install.
echo "Set the root password:"
until passwd root; do echo "Try again."; done
echo "Set the password for $NEW_USER:"
until passwd "$NEW_USER"; do echo "Try again."; done

# Hand the repository to the new user for the later stages. Keep this last: it
# moves the directory this script is running from.
rm -rf "/home/$NEW_USER/miscellaneous"
mv /root/miscellaneous "/home/$NEW_USER/miscellaneous"
chown -R "$NEW_USER:$NEW_USER" "/home/$NEW_USER/miscellaneous"
