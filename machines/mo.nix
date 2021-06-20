{ hardware, modulesPath, pkgs, ... }: {
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    hardware.lenovo-thinkpad-t420
  ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 25;
        consoleMode = "max";
      };
    };

    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-intel" ];
    initrd.availableKernelModules = [ "ehci_pci" "ahci" "firewire_ohci" "sdhci_pci" ];

    initrd.luks.devices.home = {
      device = "/dev/disk/by-partlabel/home";
      allowDiscards = true;
      bypassWorkqueues = true;
    };
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
      device = "LABEL=home";
      fsType = "ext4";
      neededForBoot = true;
    };
  };

  swapDevices = [ {
    device = "/swap";
    size = 4096;
  } ];

  networking = {
    interfaces.enp0s25.useDHCP = true;
    interfaces.wlp3s0.useDHCP = true;
    wireless = {
      enable = true;
      interfaces = [ "wlp3s0" ];
      userControlled.enable = true;
      allowAuxiliaryImperativeNetworks = true;
    };
  };

  environment.systemPackages = with pkgs; [
    efibootmgr
    wpa_supplicant_gui
    v4l-utils
  ];

  services.xserver = {
    videoDrivers = [ "intel" ];

    libinput = {
      enable = true;
      touchpad = {
        accelSpeed = "0.6";
        tapping = false;
      };
    };
  };

  system.stateVersion = "21.05";
}
