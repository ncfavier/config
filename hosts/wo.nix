{ pkgs, profilesPath, modulesPath, ... }: {
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"

    "${profilesPath}/wireguard-server.nix"
    "${profilesPath}/nginx.nix"
    "${profilesPath}/mailserver.nix"
    "${profilesPath}/weechat"
    "${profilesPath}/hydra.nix"
    "${profilesPath}/syncthing.nix"
    "${profilesPath}/ulmaoc-topic.nix"
  ];

  boot = {
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/vda";
    };

    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
  };

  swapDevices = [
    {
      device = "/swap";
      size = 4096;
    }
  ];

  networking.interfaces.ens3 = {
    useDHCP = true;
    tempAddress = "disabled";
  };

  environment.systemPackages = with pkgs; [
    rxvt-unicode-unwrapped.terminfo
  ];

  system.stateVersion = "20.09";
}
