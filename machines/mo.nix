{ config, lib, hardware, pkgs, modulesPath, ... }: {
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    hardware.lenovo-thinkpad-t420
  ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 20;
      };
    };

    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-intel" ];
    initrd.availableKernelModules = [ "ehci_pci" "ahci" "firewire_ohci" "sdhci_pci" ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-partlabel/nixos";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-partlabel/boot";
      fsType = "vfat";
    };

    "/home" = {
      device = "/dev/disk/by-partlabel/home";
      fsType = "ext4";
    };
  };

  swapDevices = [
    {
      device = "/dev/disk/by-partlabel/swap";
    }
  ];

  networking.interfaces.enp0s25 = {
    useDHCP = true;
    tempAddress = "disabled";
  };

  services.xserver.libinput = {
    enable = true;
    touchpad = {
      accelSpeed = "0.6";
      tapping = false;
    };
  };

  my.hashedPassword = "$6$YQiLlxItjY$D8bmUq29Zi557FZ3i4fcWdK4S1Nc7YH/6aUUfl3NvuTyK0rq7uKdajhChK/myhmvtN3MzIYXDo6e0hmfhuHjn0";
  my.home = "/home/n2";

  system.stateVersion = "21.03";
}
