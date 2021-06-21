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

  swapDevices = [ {
    device = "/swap";
    size = 2048;
  } ];

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

  services.syncthing.declarative.cert = builtins.toFile "syncthing-cert" ''
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
