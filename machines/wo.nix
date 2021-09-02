{ lib, config, modulesPath, pkgs, ... }: with lib; let
  interface = "ens3";
  ipv4 = "202.61.245.252";
  netmask4 = "255.255.252.0";
  gateway4 = "202.61.244.1";
  ipv6 = "2a03:4000:53:fb4::1";
  gateway6 = "fe80::1";
in {
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };

    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];

    initrd.luks.devices.nixos = {
      device = "/dev/sda2";
      allowDiscards = true;
      bypassWorkqueues = true;
    };

    kernelParams = [ "ip=${ipv4}::${gateway4}:${netmask4}::${interface}:none" ];
    initrd.network = {
      enable = true;
      ssh = {
        enable = true;
        hostKeys = map (k: k.path) config.services.openssh.hostKeys;
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "LABEL=nixos";
      fsType = "ext4";
    };

    "/boot" = {
      device = "LABEL=boot";
      fsType = "ext4";
    };
  };

  networking.interfaces.${interface} = {
    ipv4.addresses = [ {
      address = ipv4;
      prefixLength = 22;
    } ];

    ipv6.addresses = [ {
      address = ipv6;
      prefixLength = 64;
    } ];
  };

  networking.defaultGateway = {
    inherit interface;
    address = gateway4;
  };

  networking.defaultGateway6 = {
    inherit interface;
    address = gateway6;
  };

  networking.nat.externalInterface = interface;

  fonts.fontconfig.enable = false;

  my.hashedPassword = "$6$jvQ36QMw6kyzUjx$ApZlmPkvPyNAf2t51KpnocvMDo/1BubqCMR3q5jZD5OcM1awyAnTIgIeyaVl2XpAiNZPTouyuM1AOzBIGBu4m.";

  services.syncthing.cert = builtins.toFile "syncthing-cert" ''
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

  synced.saves.watch = false;

  networking.firewall.allowedTCPPorts = [ 7777 ];
  networking.firewall.allowedUDPPorts = [ 7777 ];

  system.stateVersion = "21.05";
}
