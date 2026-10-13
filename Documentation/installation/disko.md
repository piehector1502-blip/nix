# Installing nixos-laptop with disko

disko partitions and formats the disk for you, based on `hosts/nixos-laptop/disko-config-btrfs.nix`.

> **Warning:** this ERASES the whole target disk.

## 1. Boot the installer

1. Write the **NixOS Minimal ISO** (from [nixos.org](https://nixos.org/download.html)) to a USB stick.
2. In the BIOS, set **UEFI** mode and turn **Secure Boot off**, then boot from the USB stick.
3. Connect to the internet: run `sudo nmtui` for WiFi (Ethernet works automatically).

## 2. Get the config

<!-- TODO: fix the clone URL later -->
```bash
nix-shell -p git
git clone https://github.com/nicolkrit999/nix.git ~/nix
cd ~/nix
```

## 3. Choose the disk

Find your disk name:

```bash
lsblk -o NAME,SIZE,MODEL
```

Open `hosts/nixos-laptop/disko-config-btrfs.nix` (`nano hosts/nixos-laptop/disko-config-btrfs.nix`) and set `device` to your disk, for example `/dev/nvme0n1` or `/dev/sda`.

## 4. Generate the hardware file

```bash
nixos-generate-config --no-filesystems --show-hardware-config > hosts/nixos-laptop/hardware-configuration.nix
```

## 5. Partition and mount with disko

```bash
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode destroy,format,mount ./hosts/nixos-laptop/disko-config-btrfs.nix
```

The new system is now mounted at `/mnt`.

## 6. Install

```bash
git add -A
sudo nixos-install --flake .#nixos-laptop
```

Set the root password when asked. Then set the password for the user `pierre` (the account you will log in with):

```bash
sudo nixos-enter --root /mnt -c 'passwd pierre'
```

Finally run `reboot` and remove the USB stick.

## After the first boot

Your username is `pierre` unless it was changed in `hosts/nixos-laptop/default.nix`. Log in with the password you set in step 6.
