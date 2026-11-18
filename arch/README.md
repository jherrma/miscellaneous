# Arch Linux install

Minimal base first, then the desktop and applications as separate steps.

## 1. Prepare the disks (live ISO)
Boot the ISO in UEFI mode (`ls /sys/firmware/efi` must exist).

- set console to german `loadkeys de-latin1`
- set time `timedatectl set-ntp true`
- view disks with `lsblk`
- format disks with gdisk
	- EFI partition is of type ef00 and size 512MiB
- make filesystems:
	- `mkfs.vfat /dev/sda1` (efi partition)
	- `mkfs.btrfs -L <label> /dev/<...>`
- create the btrfs subvolumes. Mount the top-level volume, create them, and unmount it again,
  otherwise it stays mounted underneath and `genfstab` writes two `/` entries:
  ```
  mount /dev/sda2 /mnt
  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@home
  btrfs subvolume create /mnt/@cache
  btrfs subvolume create /mnt/@log
  umount /mnt
  ```
  For a second drive with a data subvolume:
  ```
  mount /dev/sdb1 /mnt
  btrfs subvolume create /mnt/@data
  umount /mnt
  ```
- mount the subvolumes:
  ```
  mount -o noatime,compress=zstd,discard=async,subvol=@ /dev/sda2 /mnt
  mkdir -p /mnt/{boot/efi,home,var/cache,var/log}
  mount /dev/sda1 /mnt/boot/efi
  mount -o noatime,compress=zstd,discard=async,subvol=@home /dev/sda2 /mnt/home
  mount -o noatime,compress=zstd,discard=async,subvol=@cache /dev/sda2 /mnt/var/cache
  mount -o noatime,compress=zstd,discard=async,subvol=@log /dev/sda2 /mnt/var/log
  ```
  Second drive:
  ```
  mkdir -p /mnt/data
  mount -o noatime,compress=zstd,discard=async,subvol=@data /dev/sdb1 /mnt/data
  ```

  (`space_cache=v2` is the btrfs default, so it is not listed.)

## 2. Install
Get this repository onto the live ISO (`pacman -Sy git && git clone ...`), then:

```
cd miscellaneous/arch
./install-base.sh [--cpu amd|intel] [--tz Europe/Berlin] [--hostname NAME] [--user NAME] [--keymap de-latin1]
```
It installs `packages/base.txt` with pacstrap, then runs `chroot.sh` inside the new system (time zone, locale,
hostname, GRUB, services, user with sudo, passwords). Missing options are detected, defaulted or asked for.
You will be asked to set the root and user passwords near the end; a typo just asks again.

## 3. After the first boot
Log in on the console as your user. The repository is in `~/miscellaneous`.

Wi-Fi only machine? NetworkManager is running, so connect from the console first:
```
nmcli device wifi list
nmcli device wifi connect <SSID> --ask
```

Then run, in this order:

| Script | What it does |
|---|---|
| `desktop-setup.sh` | KDE Plasma + Plasma Login Manager, PipeWire audio, Wayland, Vulkan driver, KDE apps, fonts, printing |
| `tweaks.sh` | mirror refresh timer, `/boot` backup hook, zram + sysctl tuning, journald size limit, unneeded services off, kernel audit off (`audit=0`), ufw firewall (SSH allowed if sshd is enabled) |
| `apps-setup.sh` | `packages/apps.txt`, paru + `packages/aur.txt`, snapd + snaps, Flatpaks |
| `install-neovim.sh` | Neovim and its configuration |

What gets installed is controlled by the lists in `packages/` (and `distro-independent/install-flatpaks.sh` /
`install-snaps.sh`). Edit a list, re-run the script, it is idempotent.

Blu-ray playback additionally needs a `KEYDB.cfg` in `~/.config/aacs` (see `fedora/setup-bluray-playback.sh`).

src: [https://youtu.be/hMVgkcuLIMk](https://youtu.be/hMVgkcuLIMk)
