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

  my.hashedPassword = "$6$YQiLlxItjY$D8bmUq29Zi557FZ3i4fcWdK4S1Nc7YH/6aUUfl3NvuTyK0rq7uKdajhChK/myhmvtN3MzIYXDo6e0hmfhuHjn0";

  services.syncthing.declarative.cert = builtins.toFile "syncthing-cert" ''
    -----BEGIN CERTIFICATE-----
    MIIBmzCCASCgAwIBAgIIZR/vpL1iGHwwCgYIKoZIzj0EAwIwFDESMBAGA1UEAxMJ
    c3luY3RoaW5nMB4XDTIwMTExMTAwMDAwMFoXDTQwMTEwNjAwMDAwMFowFDESMBAG
    A1UEAxMJc3luY3RoaW5nMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAE5jPi++Nycm5j
    PRvKzhRkHlw8Am1qLryxpBqFJBoeEvLtFdrBXr0JmcfbXX8htKw863cH6LX1A7G5
    8rYn/qEuquu/yawsBrU2jDRD+18H0Cz2SJkhR6ZbVIFI00ZwO3wzoz8wPTAOBgNV
    HQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMAwGA1Ud
    EwEB/wQCMAAwCgYIKoZIzj0EAwIDaQAwZgIxALy2BpsKfyvadr0T9dkikU/KPjiT
    Dg2P8CiEOW63UoGxZdgAeTQuFJDQ2IrRUvy8LQIxANrQBQ309xy3sf44pgah1PvZ
    BDS5RTdh3BYmC2aLyy2ocJM7ZA2bmaR5i6dH2YebPw==
    -----END CERTIFICATE-----
  '';

  system.stateVersion = "21.05";
}
