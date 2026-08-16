# Loxedo NixOS — Acer Nitro ANV15-51

Reproducible NixOS configuration for an Acer Nitro ANV15-51 with:

- Intel Core i7-13620H + Intel iGPU
- NVIDIA GeForce RTX 4050 Laptop GPU
- 16 GiB DDR5
- WD SN740 1 TB NVMe
- Intel eDP-1: 1920x1080 @ 165 Hz
- NVIDIA HDMI-A-2: 1920x1080 @ 74.97 Hz
- Btrfs + separate root/home/nix/swap subvolumes
- Wayland + SomeWM + Crystal Aura
- PipeWire + EasyEffects + xdg-desktop-portal-wlr
- Steam / Proton / GameMode / Gamescope
- Razer OpenRazer / Polychromatic
- Fish + Alacritty + Brave
- Declarative Flatpak + GoofCord

## Storage safety

The machine dual-boots Windows. The Windows NTFS partition and MSR partition are
intentionally preserved. Disko targets **only `/dev/nvme0n1p2`**, the Linux Btrfs
partition, while the existing EFI System Partition is reused without formatting.

The installer refuses to continue unless the expected PARTUUID/EFI UUID/Windows
filesystem checks succeed and the user types the exact confirmation string.

## Development workflow

```bash
nix flake check
sudo nixos-rebuild build --flake .#nitro-v15
```

For a clean installation from a NixOS live USB:

```bash
git clone https://github.com/Loxedo/nixos-config.git
cd nixos-config
./scripts/install.sh
```

Do not run the installer until the hardware/Wayland validation has been completed.

## GPU policy

- Intel handles the normal desktop workload.
- NVIDIA is available through PRIME render offload.
- The external HDMI display is physically wired to NVIDIA, so the RTX remains awake
  whenever that display is active.
- Explicit dGPU execution is available through `nvidia-offload` / `nvidia-run`.

## Memory policy

- zram: up to 75% of physical RAM, high priority
- NVMe swapfile: 32 GiB, low priority
- `vm.swappiness=150`
- `systemd-oomd` enabled

This is intentionally aggressive for heavy multitasking, but interactive applications
are not forced entirely into swap.
