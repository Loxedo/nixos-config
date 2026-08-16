{ pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = false;

    # Fine-grained runtime power management is useful when the HDMI display is
    # disconnected. With HDMI-A-2 physically wired to the RTX, the dGPU will
    # remain awake whenever that monitor is active.
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools
    mesa-demos
    nvtopPackages.nvidia
  ];
}
