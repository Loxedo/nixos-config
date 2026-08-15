# NixOS — Acer Nitro V15 / Crystal Aura / Wayland

Personal, reproducible NixOS configuration for the Acer Nitro ANV15-51.

## Hardware profile

- Acer Nitro ANV15-51, firmware V1.52
- Intel Core i7-13620H
- Intel UHD Graphics, PCI `0000:00:02.0`
- NVIDIA GeForce RTX 4050 Laptop, PCI `0000:01:00.0`
- 16 GiB DDR5, 2×8 GiB
- WD PC SN740 1 TB NVMe
- Internal BOE 1920×1080 @ 165 Hz (`eDP-1`)
- External Samsung LF22T35 1920×1080 @ 74.97 Hz (`HDMI-A-2`)
- Razer BlackWidow V4 X `1532:0293`
- Razer BlackShark V2 HS USB `1532:056e`
- Attack Shark wireless mouse receiver `1d57:fa60`

## Design

- NixOS + flakes
- Home Manager as a NixOS module
- Wayland compositor: SomeWM
- Desktop configuration: Crystal Aura, consumed from its upstream Git reference
- NVIDIA open kernel modules + PRIME offload
- PipeWire/WirePlumber
- zram-first memory pressure handling
- Steam/GameMode/MangoHud

## Important GPU topology

The internal eDP panel is attached to the Intel GPU while the external HDMI connector is attached to the RTX 4050. This is not a simple all-displays-on-iGPU Optimus layout and must be validated with the Wayland compositor before the destructive install stage.

## Upstream sources

- Crystal Aura: https://github.com/namishh/crystal/tree/aura
- SomeWM: https://github.com/trip-zip/somewm

## Status

This is the initial reproducible scaffold. The installer intentionally does **not** format disks yet. The next hardening pass should validate SomeWM + NVIDIA multi-GPU presentation, complete the Crystal Aura Wayland adaptations, finalize the fresh Btrfs partition scheme, and then enable the destructive installation stage.
