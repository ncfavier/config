{ config, modulesPath, pkgs, ... }: let
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
        port = builtins.head config.services.openssh.ports;
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

  system.stateVersion = "21.05";
}
