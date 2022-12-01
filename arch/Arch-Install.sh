#!/bin/bash
# Use this script after you set up your partitions
# Will install Arch into /mnt

echo "This script will install Arch Linux and can only be executed after the partitions are set up and mounted to /mnt."

# AMD or Intel
echo "Do you have an AMD or Intel CPU?"
read cpu

if [ "$cpu" != "intel" ] && [ "$cpu" != "amd" ];
then
	echo "please choose 'intel' or 'amd'"
	exit
fi

# Timezone
echo "Whats you time zone? (e.g. Europe/Berlin) WARNING: this variable is not spell checked!!"
read timezone

# User
echo "Set the user name for you new system:"
read username

# Choose desktop
echo "Do you want Gnome, KDE or no desktop? (Possible values: gnome, kde, none)"
read desktop
if [ "$desktop" != "gnome" ] && [ "$desktop" != "kde" ] && [ "$desktop" != "none" ];
then 
	echo "Please specify one of 'gnome', 'kde' or 'none'. You typed '$desktop'"
	exit
fi 
echo "You chose $desktop"

echo "Installing Arch Base into /mnt"
pacstrap /mnt base base-devel linux-lts linux-firmware $cpu-ucode sysfsutils btrfs-progs cryptsetup device-mapper dhcpcd dialog e2fsprogs grml-zsh-config grub gptfdisk less lvm2 mkinitcpio nano neofetch netctl nvme-cli os-prober zsh vim
echo "Done installing Arch Base\n\n"

echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab
echo "Generating fstab done\n\n"

echo "Moving into /mnt"
arch-chroot /mnt


echo "Setting timezone to $timezone"
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc

echo "Setting up network"
echo "$username" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $username.localdomain $username" >> /etc/hosts


echo "Installing system"
echo "Installing iwd. If WIFI is not auto connection change setting in /etc/iwd/main.conf"
pacman -S --noconfirm grub efibootmgr networkmanager network-manager-applet networkmanager-openvpn iwd mtools dialog dosfstools reflector linux-lts-headers avahi xdg-user-dirs xdg-utils gvfs gvfs-smb nfs-utils ntfs-3g inetutils dnsutils blueman bluez-tools alsa-utils alsa-plugins alsa-firmware alsa-oss openssh rsync htop acpi acpid nss-mdns git pipewire pipewire-alsa pipewire-pulse xdg-desktop-portal-gtk gst-plugin-pipewire man-db man-pages 
echo "Install done\n\n"


echo "Installing GRUB"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux
echo "Installing GRUB done\n\n"

echo "Enabling Services:"
echo "Enabling acpid"
systemctl enable acpid
echo "Enabling avahi-daemon"
systemctl enable avahi-daemon
echo "Enabling bluetooth"
systemctl enable bluetooth
echo "Enabling fstrim.timer"
systemctl enable fstrim.timer
echo "Enabling NetworkManager"
systemctl enable NetworkManager
echo "Enabling reflector.timer"
systemctl enable reflector.timer


echo "Adding user"
useradd -mU -s /bin/zsh -G sys,log,network,floppy,scanner,power,rfkill,users,video,storage,optical,lp,audio,wheel,adm $username
passwd $username

echo "In the next step you need to add yourself to the sudo users. Uncomment '%wheel ALL=(ALL) ALL'"
echo "Press return to coninue"
read tmp
EDITOR=nano visudo

echo "Mkinitcpio linux-lts"
mkinitcpio -p linux-lts

echo "Setting up pacman sources"
mv /etc/xdg/reflector.conf /etc/xdg/reflector.conf.orig
echo "--country Germany,Netherlands,France\n--age 12\n--protocol https\n--latest 3\n--sort rate\n--save /etc/pacman.d/mirrorlist" >> /etc/xdg/reflector.conf

echo "Creating backup hook for kernel upgrades"
mkdir -p /etc/pacman.d/hooks
echo "[Trigger]\nOperation = Upgrade\nOperation = Install\nOperation = Remove\nType = Path\nTarget = usr/lib/modules/*/vmlinuz\n\n[Action]\nDepends = rsync\nDescription = Backing up /boot...\nWhen = PreTransaction\nExec = /usr/bin/rsync -a --delete /boot /boot-backup" >> /etc/pacman.d/hooks/50-bootbackup.hook


if [ "$desktop" = "gnome" ];
then
	echo "Installing GNOME"
	# GNOME Wayland
	sudo pacman -S --noconfirm \
	wayland \
	wayland-utils \
	xorg \
	xorg-server \
	gdm \
	gnome \
	gnome-session \
	filemanager-actions
	sudo systemctl enable gdm.service
	localectl set-locale LANG="en_US.UTF-8"
	localectl set-x11-keymap de
fi

if [ "$desktop" = "kde" ];
then
	echo "Installing KDE"
	# KDE Wayland
	sudo pacman -S --noconfirm \
	wayland \
	wayland-utils \
	xorg \
	xorg-server \
	sddm \
	plasma \
	plasma-wayland-session \
	print-manager
	sudo systemctl enable sddm.service
fi

if [ "$desktop" = "gnome" ] || [ "$desktop" = "kde" ];
then
	echo "Installing basic desktop packages"
	sudo pacman -S --noconfirm flatpak firefox xournalpp papirus-icon-theme noto-fonts ttf-opensans cups system-config-printer adobe-source-code-pro-fonts
	sudo systemctl enable cups.socket
fi

echo "Installing linux headers"
sudo pacman -S --noconfirm linux-lts-headers


echo "Exiting chroot and unmounting drives"
exit
umount -a

echo "Arch sucessfully installed"
