{ hardware, pkgs, ... }: {
  imports = with hardware; [
    notDetected
    lenovo-thinkpad-t420
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

  services.syncthing.cert = builtins.toFile "syncthing-cert" ''
    -----BEGIN CERTIFICATE-----
    MIIBmjCCASCgAwIBAgIIU2Crk9b6ZekwCgYIKoZIzj0EAwMwFDESMBAGA1UEAxMJ
    c3luY3RoaW5nMB4XDTE4MDgwNzIzMjMzNVoXDTQ5MTIzMTIzNTk1OVowFDESMBAG
    A1UEAxMJc3luY3RoaW5nMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEh18xcRgABADs
    7eMwystTMeUC65E+dP/MJf6tOBPRAumbP2LanrtRAW4it1KjJ8QiwtRe3t7+SlvN
    CdC26ni4NH6B9fYhN1vL0pjHy3cun5ouwLxC4tTISyrirJZl4UAPoz8wPTAOBgNV
    HQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMAwGA1Ud
    EwEB/wQCMAAwCgYIKoZIzj0EAwMDaAAwZQIxAJwtZBBG6iGgiCE5Xsfebxltw/Uy
    kjrbRaEBW8Dp+DcmfJjWPz1tW8WwBd3LGdadswIwaE6CkCKXg7/Om2O9WCs8qnjU
    qR/eLxSYOw2/n12rN2cEsWz6SI+vpfDIZoTYxvDP
    -----END CERTIFICATE-----
  '';

  system.stateVersion = "21.05";
}
