# Manual installation (nixos-laptop)

This guide is for the same machine as [disko.md](./disko.md), but with the partitions made by hand. Most people should use the disko guide instead: it is shorter and does this for you.

Because disko is part of this config, the simplest path is still disko. Only follow this guide if you need a custom layout (for example dual boot). In that case, either edit `hosts/nixos-laptop/disko-config-btrfs.nix` to match, or remove the two disko lines (`inputs.disko.nixosModules.disko` and `./disko-config-btrfs.nix`) from `hosts/nixos-laptop/system.nix` and list your own `fileSystems` there.

## 1. Boot the installer

1. Write the **NixOS Minimal ISO** to a USB stick, set the BIOS to **UEFI** with **Secure Boot off**, and boot it.
2. Connect to the internet (`sudo nmtui` for WiFi).

## 2. Partition

Use `lsblk` to find the disk, then `sudo cfdisk /dev/nvme0n1` (use your own disk name):

1. Create a `1G` partition of type **EFI System**.
2. Create a second partition with the rest of the space (**Linux filesystem**).
3. Write and quit.

## 3. Format and mount

Replace `nvme0n1p1` and `nvme0n1p2` with your partitions.

```bash
sudo mkfs.fat -F 32 /dev/nvme0n1p1
sudo mkfs.btrfs -f /dev/nvme0n1p2
sudo mount /dev/nvme0n1p2 /mnt
sudo mkdir -p /mnt/boot
sudo mount -o umask=0077 /dev/nvme0n1p1 /mnt/boot
```

## 4. Install

<!-- TODO: fix the clone URL later -->
```bash
nix-shell -p git
git clone https://github.com/nicolkrit999/nix.git ~/nix
cd ~/nix
sudo nixos-generate-config --root /mnt --show-hardware-config > hosts/nixos-laptop/hardware-configuration.nix
```

Remove the two disko lines from `hosts/nixos-laptop/system.nix` as described above, then:

```bash
git add -A
sudo nixos-install --flake .#nixos-laptop
```

Set the root password when asked. Then set the password for the user `pierre`:

```bash
sudo nixos-enter --root /mnt -c 'passwd pierre'
```

Finally `reboot`.
