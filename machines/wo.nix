{ pkgs, modulesPath, ... }: {
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/vda";
    };

    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
  };

  fileSystems."/" = {
    device = "LABEL=nixos";
    fsType = "ext4";
  };

  swapDevices = [ {
    device = "/swap";
    size = 6144;
  } ];

  networking.wan = {
    interface = "ens3";
    ipv4 = "199.247.15.22";
    ipv6 = "2001:19f0:6801:413:5400:2ff:feff:23e0";
  };

  networking.interfaces.ens3.useDHCP = true;

  environment.systemPackages = with pkgs; [
    alacritty.terminfo
  ];

  system.stateVersion = "21.05";
}
