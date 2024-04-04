{
  identity = {
    isServer = true;
    ipv4 = [ "46.38.232.212" ];
    ipv6 = [ "2a03:4000:2:fd1::42" ];
    sshPort = 2242;
    wireguard = {
      ipv4 = "10.42.0.1";
      ipv6 = "fd42::0:1";
      publicKey = "wYNBfzEDs9E10z/wfeWuOe6u63SFW+7EWdGHYrU1SUc=";
    };
    syncthing.id = "26Z2VZW-TJEASC6-CWQHMCJ-QMGT4MJ-YTTUW7V-M6IIUQU-LY3SCYS-UQ6FGAY";
  };

  nixos = { lib, this, config, modulesPath, pkgs, ... }: with lib; let
    interface = "ens3";
  in {
    imports = [
      "${modulesPath}/profiles/qemu-guest.nix"
    ];

    boot = {
      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot = {
          enable = true;
          configurationLimit = 3;
        };
      };

      kernelPackages = pkgs.linuxPackages_latest;
      initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];

      initrd.luks.devices.nixos = {
        device = "/dev/disk/by-partlabel/nixos";
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
    };

    swapDevices = [ {
      device = "/swap";
      size = 8 * 1024;
    } ];

    environment.systemPackages = with pkgs; [
      efibootmgr
    ];

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
  };
}
