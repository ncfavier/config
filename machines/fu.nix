{
  identity = {
    isStation = true;
    wireguard = {
      ipv4 = "10.42.1.1";
      ipv6 = "fd42::1:1";
      publicKey = "v1MDB6hEYKdBwdVN/rOnOGB82h3xTQpHwU3CAcctGWg=";
    };
    syncthing.id = "VVLGMST-LA633IY-KWESSFD-7FFF7LE-PNJAEML-ZXZSBLL-ATLQHPT-MUHEDAR";
  };

  nixos = { hardware, config, pkgs, ... }: {
    imports = with hardware; [
      notDetected
      common-cpu-intel-cpu-only
      common-pc-ssd
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

      kernelModules = [ "kvm-intel" ];
      # initrd.kernelModules = [ "nouveau" ];
      initrd.availableKernelModules = [ "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];

      initrd.luks.devices.nixos = {
        device = "/dev/disk/by-partlabel/nixos";
        allowDiscards = true;
        bypassWorkqueues = true;
      };

      swraid.enable = false;
    };

    services.xserver.videoDrivers = [ "nvidia" ];
    nixpkgs.config.nvidia.acceptLicense = true;

    hardware.nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.legacy_390;
      nvidiaSettings = true;
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
    };

    swapDevices = [ {
      device = "/swap";
      size = 8 * 1024;
    } ];

    networking.wireless.interfaces = [ "wlp3s0" ];

    environment.systemPackages = with pkgs; [
      efibootmgr
    ];

    my.hashedPassword = "$y$j9T$4ixQiecsV/ucuBhr6jEte1$4mQUZgQsZXNlA2rY5RfntCTPEZ7ZuZc64L1k9VO5tQ8";

    services.syncthing.cert = builtins.toFile "syncthing-cert" ''
      -----BEGIN CERTIFICATE-----
      MIIBmjCCASCgAwIBAgIIRaL8rxe74e0wCgYIKoZIzj0EAwMwFDESMBAGA1UEAxMJ
      c3luY3RoaW5nMB4XDTE4MDcwMzIwMTExM1oXDTQ5MTIzMTIzNTk1OVowFDESMBAG
      A1UEAxMJc3luY3RoaW5nMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEjVHr6jb7E73k
      sJwqCw4AE2WoIV3WRZy4ITdg/XxP19N5reFdqyVfjp4LXIoZto8SWfbQ9pPlgY21
      eDTr/QIASnMI2Oc5Hcmb6ozv49AuQSef85UoSUU90YWkGNGODWuxoz8wPTAOBgNV
      HQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMAwGA1Ud
      EwEB/wQCMAAwCgYIKoZIzj0EAwMDaAAwZQIxAMcB86gR/XSiEVrDEQsDbRxn/kzJ
      vSzd4X9+RhQ+4i9dYYNPigt4xCxgewpyt0UmVAIwMf25wwJosKeBNFIH6CaEn/4g
      kjz2Vh63ayu5iLe7cOhUUIvmDuEW2wmxe/6Iz3LR
      -----END CERTIFICATE-----
    '';

    system.stateVersion = "21.05";
  };
}
