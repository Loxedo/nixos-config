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

Boot the NixOS live USB **in UEFI mode**, open a terminal, and run:

```bash
git clone https://github.com/Loxedo/nixos-config.git
cd nixos-config
./install.sh
```

The live ISO is not your installed NixOS system, so its Nix configuration cannot
inherit `nix.settings.experimental-features` from this repository before the target
system exists. The installer therefore sets `NIX_CONFIG` for its own process tree.
This enables `nix-command` and flakes without requiring a manual nix.conf edit.

Before the disk is touched, the installer builds:

```text
nixosConfigurations.nitro-v15.config.system.build.toplevel
```

This is intentional. A failure in SomeWM, LGI, wlroots, NVIDIA, or any other system
component stops the installer before partitioning or formatting the disk.

After the preflight build succeeds, the installer:

1. requires a normal live-user shell rather than root;
2. verifies that the installer was booted in UEFI mode;
3. verifies that exactly one internal NVMe disk exists;
4. verifies that the disk is `/dev/nvme0n1`, matching this host's Disko layout;
5. prints the current disk layout;
6. requires the exact confirmation `ERASE-NVME0N1`;
7. uses the Disko revision pinned in `flake.lock`;
8. runs Disko to destroy, repartition, format, and mount the disk;
9. copies the flake into `/mnt/etc/nixos`;
10. runs `nixos-install --flake /mnt/etc/nixos#nitro-v15`; and
11. prompts for the `loxedo` user's password before rebooting.

No password or password hash is committed to the public repository.

## SomeWM packaging

SomeWM 1.4.3 performs a C-based LGI probe during Meson configuration. The Nix
package uses Lua 5.3 together with the matching `lua53Packages.lgi` package and
exposes LGI's Lua module paths explicitly.

Do **not** replace `PKG_CONFIG_PATH` inside the derivation. Nix constructs that
variable from the build inputs. Overriding it with only LGI's directory hides the
pkg-config files for wlroots, Wayland, GLib, Cairo, and related dependencies and can
produce misleading `wlroots not found` errors.

## Development validation

```bash
./scripts/validate.sh
nix flake check --no-write-lock-file
nix build .#nixosConfigurations.nitro-v15.config.system.build.toplevel --no-link --no-write-lock-file
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
