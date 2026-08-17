{ pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Intel drives the desktop in PRIME offload mode; NVIDIA is available on demand.
  services.xserver.videoDrivers = [ "modesetting" "nvidia" ];

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = false;

    powerManagement.enable = true;
    powerManagement.finegrained = true;

    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      # lspci addresses converted to the NixOS PRIME format for this machine:
      # Intel 0000:00:02.0 -> PCI:0@0:2:0
      # NVIDIA 0000:01:00.0 -> PCI:1@0:0:0
      intelBusId = "PCI:0@0:2:0";
      nvidiaBusId = "PCI:1@0:0:0";
    };
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools
    mesa-demos
    nvtopPackages.nvidia
  ];
}
