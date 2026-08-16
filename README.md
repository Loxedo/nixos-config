# Loxedo NixOS — Acer Nitro ANV15-51

Reproducible NixOS configuration for an Acer Nitro ANV15-51 with:

- Intel Core i7-13620H + Intel iGPU
- NVIDIA GeForce RTX 4050 Laptop GPU
- 16 GiB DDR5
- WD SN740 1 TB NVMe
- Btrfs with separate root/home/nix/swap/cache/log subvolumes
- Wayland + SomeWM + Crystal Aura
- PipeWire + EasyEffects + xdg-desktop-portal-wlr
- Steam / Proton / GameMode / Gamescope
- Razer OpenRazer / Polychromatic
- Fish + Alacritty + Brave
- Declarative Flatpak + GoofCord

## Installation

This repository is for a **clean single-disk installation**. Windows is no longer
present on the machine, so the installer intentionally recreates the entire GPT
partition table on `/dev/nvme0n1`.

Boot the NixOS live USB, open a terminal, and run:

```bash
git clone https://github.com/Loxedo/nixos-config.git
cd nixos-config
./install.sh
```

The installer:

1. requires a normal live-user shell rather than root;
2. verifies that exactly one internal NVMe disk exists;
3. verifies that the disk is `/dev/nvme0n1`, matching this host's Disko layout;
4. prints the current partition table;
5. requires the exact confirmation `ERASE-NVME0N1`;
6. uses the Disko revision pinned in `flake.lock`;
7. runs Disko to destroy, repartition, format, and mount the disk;
8. copies the flake into `/mnt/etc/nixos`;
9. runs `nixos-install --flake /mnt/etc/nixos#nitro-v15`; and
10. prompts for the `loxedo` user's password before rebooting.

The only disk-destructive operation is therefore behind an explicit confirmation.
No password or password hash is committed to the public repository.

## Development validation

```bash
./scripts/validate.sh
nix flake check
sudo nixos-rebuild build --flake .#nitro-v15
```

## GPU policy

- Intel handles the normal desktop workload.
- NVIDIA is available through PRIME render offload.
- Explicit dGPU execution is available through `nvidia-offload` / `nvidia-run`.

## Memory policy

- zram: up to 75% of physical RAM, high priority
- NVMe swapfile: 16 GiB, low priority
- `vm.swappiness=180`
- `systemd-oomd` enabled

The memory configuration is intentionally aggressive for heavy multitasking and gaming.
