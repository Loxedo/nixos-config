{ lib, ... }:
{
  # Memory configuration for 16GB RAM + RTX 4050 laptop
  # - zram: Compressed swap in RAM (high priority) - up to 12GB
  # - NVMe swapfile: Fallback storage (low priority) - 16GB
  # This provides aggressive memory management for gaming/multitasking

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 75;  # 75% of 16GB = 12GB
    priority = 100;      # High priority: use this first
  };

  # NVMe-backed swapfile as secondary layer
  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 16 * 1024;  # 16 GiB (reduced from 32 to save space)
      priority = 5;      # Low priority: fallback after zram is full
    }
  ];

  # Kernel tuning for memory management
  boot.kernel.sysctl = {
    # Aggressive swap to prevent OOM kills
    "vm.swappiness" = 180;

    # Cluster memory writes to reduce I/O overhead
    "vm.page-cluster" = 3;

    # Reduce cache pressure (keep caches longer)
    "vm.vfs_cache_pressure" = 50;

    # Reduce writeback latency for smoother I/O
    "vm.dirty_ratio" = 5;
    "vm.dirty_background_ratio" = 2;

    # Improve memory compaction (useful for gaming)
    "vm.extfrag_threshold" = 500;
    "vm.compact_unevictable_allowed" = 1;
  };

  # Protect the desktop's user slices as well as system/root workloads.
  systemd.oomd = {
    enable = true;
    enableSystemSlice = true;
    enableRootSlice = true;
    enableUserSlices = true;
  };
}
