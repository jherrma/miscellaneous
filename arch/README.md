# Setup
- set console to german `loadkeys de-latin1`
- set time `timedatectl set-ntp true`
- update mirrorlist `reflector --country Germany,France,Belgium,Netherlands --age 12 --protocol https --latest 3 --sort rate --save /etc/pacman.d/mirrorlist`
- update database `pacman -Syy`
- view disks with `lsblk`
- format disks with gdisk
	- EFI partition is of type ef00 and size 512MiB
- make filesystems:
	- mkfs.vfat /dev/sda1 (efi partition)
	- mkfs.btrfs -L <label> /dev/<...>
- create btrfs subvolumes
	- cd into /mnt and create dirs
	- cd ..
- mount drives/volumes
  - `mount /dev/sda1 /mnt/boot/efi`
  - `mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@ /dev/sda2 /mnt`
  - `mount -o noatime,compress=zstd,space_caceh,discard=async,subvol=@home /dev/sda2 /mnt/home`
  - `mount -o noatime,compress=zstd,space_caceh,discard=async,subvol=@cache /dev/sda2 /mnt/var/cache`
  - `mount -o noatime,compress=zstd,space_caceh,discard=async,subvol=@log /dev/sda2 /mnt/var/log`
  
  If you want to mount a second drive:
	- `mount -o noatime,compress=zstd,space_caceh,discard=async,subvol=@data /dev/sdb1 /mnt/data`
  
- install arch










src: [https://youtu.be/hMVgkcuLIMk](https://youtu.be/hMVgkcuLIMk)
