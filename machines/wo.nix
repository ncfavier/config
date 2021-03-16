{ config, pkgs, modulesPath, ... }: {
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

    initrd.luks.devices.nixos.device = "/dev/sda2";

    kernelParams = [ "ip=202.61.245.252::202.61.244.1:255.255.252.0::ens3:none" ];
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

  networking.wan = {
    interface = "ens3";
    ipv4 = "202.61.245.252";
    ipv6 = "2a03:4000:53:fb4:1869:15ff:fe71:8ab";
  };

  networking.interfaces.ens3 = {
    ipv4.addresses = [ {
      address = "202.61.245.252";
      prefixLength = 22;
    } ];
    ipv6.addresses = [ {
      address = "2a03:4000:53:fb4:1869:15ff:fe71:8ab";
      prefixLength = 64;
    } ];
  };

  networking.defaultGateway = {
    address = "202.61.244.1";
    interface = "ens3";
  };

  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "ens3";
  };

  environment.systemPackages = with pkgs; [
    alacritty.terminfo
  ];

  fonts.fontconfig.enable = false;

  system.stateVersion = "21.05";
}
