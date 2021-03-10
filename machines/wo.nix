{ pkgs, modulesPath, ... }: {
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/vda";
      # device = "/dev/sda";
    };

    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
    # initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];

    # initrd.luks.devices.nixos.device = "/dev/sda2";

    # initrd.network = {
    #   enable = true;
    #   ssh = {
    #     enable = true;
    #     port = 2242;
    #     hostKeys = [
    #     ];
    #   };
    # };
  };

  fileSystems."/" = {
    device = "LABEL=nixos";
    fsType = "ext4";
  };

  # fileSystems."/boot" = {
  #   device = "LABEL=boot";
  #   fsType = "ext4";
  # };

  swapDevices = [ {
    device = "/swap";
    size = 6144;
    # size = 2048;
  } ];

  networking.wan = {
    interface = "ens3";
    ipv4 = "199.247.15.22";
    ipv6 = "2001:19f0:6801:413:5400:2ff:feff:23e0";
    # ipv4 = "202.61.245.252";
    # ipv6 = "2a03:4000:53:fb4:1869:15ff:fe71:8ab";
  };

  networking.interfaces.ens3.useDHCP = true;

  environment.systemPackages = with pkgs; [
    alacritty.terminfo
  ];

  system.stateVersion = "21.05";
}
