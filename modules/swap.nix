{ ... }:
{
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  # Deliberately not creating the 32 GiB swapfile yet. Once the clean-install
  # filesystem layout is finalized, the installer will provision the SSD swap
  # according to the final hibernation policy.
}
