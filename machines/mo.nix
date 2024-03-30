{
  identity = {
    isStation = true;
    wireguard = {
      ipv4 = "10.42.2.1";
      ipv6 = "fd42::2:1";
      publicKey = "tsvrIdHACcHMhtaHQt2tVE+2FO1LMdtiAlSXPNMuHFc=";
    };
    syncthing.id = "WO4GV6E-AJGKLLQ-M7RZGFT-WY7CCOW-LXODXRY-F3QPEJ2-AXDVWKR-SWBGDQP";
  };

  nixos = { inputs, hardware, pkgs, ... }: {
    imports = with hardware; [
      notDetected
      lenovo-thinkpad-t420
    ];

    services.tlp.settings = {
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
      RESTORE_THRESHOLDS_ON_BAT = 1;
    };

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
      };

      swraid.enable = false;
    };

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };

      "/boot" = {
        device = "/dev/disk/by-label/boot";
        fsType = "vfat";
        options = [ "umask=0077" ];
      };

      "/home" = {
        device = "/dev/disk/by-label/home";
        fsType = "ext4";
        neededForBoot = true;
      };
    };

    swapDevices = [ {
      device = "/swap";
      size = 4 * 1024;
    } ];

    networking.wireless.interfaces = [ "wlp3s0" ];

    environment.systemPackages = with pkgs; [
      efibootmgr
      v4l-utils
    ];

    services.xserver.videoDrivers = [ "intel" ];

    my.hashedPassword = "$y$j9T$qOTfNGYwzLlwcvYq8OwdR1$br09oz/1NqEPjpPz8LsKyCTve9tv4.k5hkfOlxS53C5";

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
  };
}
