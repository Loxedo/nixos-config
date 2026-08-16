{ ... }:
{
  # 12 GiB maximum compressed swap in RAM, plus a 32 GiB SSD-backed swapfile.
  # zram is given a higher priority so memory pressure first uses compression
  # before falling back to the NVMe swapfile.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 75;
    priority = 100;
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 32 * 1024;
      priority = 5;
    }
  ];

  boot.kernel.sysctl = {
    "vm.swappiness" = 150;
    "vm.page-cluster" = 0;
    "vm.vfs_cache_pressure" = 50;
  };
}
