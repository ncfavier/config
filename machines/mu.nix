{ lib, config, modulesPath, pkgs, ... }: with lib; let
  interface = "enp1s0";
in {
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/vda";
    };

    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];

    initrd.luks.devices.nixos = {
      device = "/dev/vda2";
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

  networking.interfaces.${interface}.useDHCP = true;
  networking.nat.externalInterface = interface;

  my.hashedPassword = "$6$SVHTxpoS0lwPgSjI$q9PATa2ObrGrU0ARBHQsJFK7O3T2fvtaMuzXQ8q4B1QAti7O5F.YGU./q9a0dmAK953Mbm2R/O2/TiXmaSEEH.";

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
}