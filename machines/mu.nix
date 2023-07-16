{ lib, this, config, modulesPath, pkgs, ... }: with lib; let
  interface = "ens3";
in {
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/sda";
      configurationLimit = 3;
    };

    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];

    initrd.luks.devices.nixos = {
      device = "/dev/sda2";
      allowDiscards = true;
      bypassWorkqueues = true;
    };

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
    useDHCP = true;
    ipv6.addresses = map (address: {
      inherit address;
      prefixLength = 64;
    }) this.ipv6;
  };

  networking.nat.externalInterface = interface;

  my.hashedPassword = "$y$j9T$rksnGUkW.ykeSovIaFxEr/$73iWg3Xzj86ulWnNzGj1AXEZD4QYhb9vN3Cxx2RC6q0";

  services.syncthing.cert = builtins.toFile "syncthing-cert" ''
    -----BEGIN CERTIFICATE-----
    MIICHDCCAaKgAwIBAgIIH6cPFnTmDRIwCgYIKoZIzj0EAwIwSjESMBAGA1UEChMJ
    U3luY3RoaW5nMSAwHgYDVQQLExdBdXRvbWF0aWNhbGx5IEdlbmVyYXRlZDESMBAG
    A1UEAxMJc3luY3RoaW5nMB4XDTIyMDIyNDAwMDAwMFoXDTQyMDIxOTAwMDAwMFow
    SjESMBAGA1UEChMJU3luY3RoaW5nMSAwHgYDVQQLExdBdXRvbWF0aWNhbGx5IEdl
    bmVyYXRlZDESMBAGA1UEAxMJc3luY3RoaW5nMHYwEAYHKoZIzj0CAQYFK4EEACID
    YgAEFoS7su21UJs0j05DET3StK2tnUIhdt+h0tASYNErAAgREA6SUhkKbOr3VrLw
    +oJ1cBUQa2PXiN1gDvErU2oU8i8W3uvzCAMfi8R59tG++hJcPm/m5zcwCqpnzvNi
    59gDo1UwUzAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsG
    AQUFBwMCMAwGA1UdEwEB/wQCMAAwFAYDVR0RBA0wC4IJc3luY3RoaW5nMAoGCCqG
    SM49BAMCA2gAMGUCMQCo2zN5cNpw4X9zUqHZMyhTHp/k1TT6AiMfigIARH4EeABN
    9vYX9utweWLl5hO6qw0CMCz5OpVIuwBMeXlVXTK60zSpfSLSH01eZxblJmpYu1WF
    sC7hqUZY2soaWi4wp2SRnQ==
    -----END CERTIFICATE-----
  '';

  system.stateVersion = "22.05";

  services.bothendieck.enable = true;
  services.my-lambdabot.enable = true;

  swapDevices = [ {
    device = "/swap";
    size = 8192;
  } ];
}
