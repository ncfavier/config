{ lib, config, modulesPath, pkgs, ... }: with lib; let
  interface = "ens3";
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

    kernelParams = [ "ip=202.61.245.252::202.61.244.1:255.255.252.0::${interface}:none" ];
    initrd.network = {
      enable = true;
      ssh = {
        enable = true;
        port = head config.services.openssh.ports;
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
      address = "202.61.245.252";
      prefixLength = 22;
    } ];
    ipv6.addresses = [ {
      address = "2a03:4000:53:fb4::1";
      prefixLength = 64;
    } ];
  };

  networking.defaultGateway = {
    address = "202.61.244.1";
    inherit interface;
  };

  networking.defaultGateway6 = {
    address = "fe80::1";
    inherit interface;
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

  services.terraria = {
    enable = true;
    openFirewall = true;
    noUPnP = true;
    maxPlayers = 10;
  };
  my.extraGroups = [ "terraria" ];

  system.stateVersion = "21.05";
}
