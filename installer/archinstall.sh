#!/bin/bash

set -ae

network=""
disk=""
hostname=""
user=""
password=""
keyboard=""
locale=""
timezone=""
cpu=""

read -p "Enter the disk you want to write on: " disk

read -p "Enter the hostname: " hostname

read -p "Enter the username: " user

read -p "Enter the password: " password

read -p "Enter key map for keyboard: " keyboard

read -p "Enter the locale: " locale

read -p "Enter the timezone: " timezone

read -p "Enter your CPU brand: " cpu 

ip addr
read -p "Enter what network device you wanna use: " network

wipefs -af ${disk}
cfdisk ${disk}

if [[ "$disk" == "/dev/nvme0n1" ]]; then
    mkfs.ext4 "${disk}p3"
    mkswap "${disk}p2"
    mkfs.fat -F 32 "${disk}p1"

    mount "${disk}p3" /mnt
    mount --mkdir "${disk}p1" /mnt/boot
    swapon "${disk}p2"
else
    mkfs.ext4 "${disk}3"
    mkswap "${disk}2"
    mkfs.fat -F 32 "${disk}1"

    mount "${disk}3" /mnt
    mount --mkdir "${disk}1" /mnt/boot
    swapon "${disk}2"
fi

echo "Installing base system..."
pacstrap -K /mnt base base-devel sudo linux linux-headers linux-firmware sof-firmware grub efibootmgr nano iwd grep git sed "$cpu"-ucode networkmanager seatd

echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab 

# Chroot into the new system
echo "Chrooting into system..."
arch-chroot /mnt <<EOF
set -euo pipefail

# Error handling
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

timedatectl set-ntp true
loadkeys "$keyboard"

# Set timezone
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc

# Localization
loadkeys "$keyboard"
echo "$locale UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=$locale" > /etc/locale.conf
echo "KEYMAP=$keyboard" > /etc/vconsole.conf

# Hostname
echo "$hostname" > /etc/hostname

# Set root password
echo "root:$password" | chpasswd

# Creating user
if id "$user" &>/dev/null; then
    echo "User already exists."
else
    useradd -m -G wheel "$user"
    echo "$user:$password" | chpasswd
    echo "%wheel ALL=(ALL) ALL" | tee -a /etc/sudoers > /dev/null
    usermod -aG audio,video,lp,input "$user"
    echo "User $user created and configured."
fi 

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
systemctl enable iwd.service
sudo systemctl enable systemd-networkd
sudo systemctl enable systemd-resolved 
systemctl enable NetworkManager 
systemctl enable seatd

sudo tee /etc/systemd/network/20-wired.network <<NET
[Match]
Name=$network
[Network]
DHCP=yes
NET

EOF

# Unmount the partitions
echo "Unmounting partitions..."
umount -R /mnt

reboot
