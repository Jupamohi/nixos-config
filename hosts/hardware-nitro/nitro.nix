{ config, lib, pkgs, ... }: {
  networking.hostName = lib.mkForce "nitro";

  # Dual boot: ESP pequeña de Windows en /efi, kernels en una partición XBOOTLDR en /boot
  boot.loader.efi.efiSysMountPoint = "/efi";
  boot.loader.systemd-boot.xbootldrMountPoint = "/boot";
  time.hardwareClockInLocalTime = true;
  boot.supportedFilesystems = [ "ntfs" ];
  boot.loader.systemd-boot.extraInstallCommands = ''
    ${pkgs.gnused}/bin/sed -i 's/^default .*/default auto-windows/' /efi/loader/loader.conf
  '';
  zramSwap.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  services.spice-vdagentd.enable = lib.mkForce false;
}
