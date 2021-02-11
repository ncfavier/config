{ inputs, config, lib, pkgs, me, profilesPath, modulesPath, ... }: {
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t420

    "${profilesPath}/graphical.nix"
  ];

  boot = {
    loader.efi.canTouchEfiVariables = true;
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 20;
    };

    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-intel" ];
    initrd.availableKernelModules = [ "ehci_pci" "ahci" "firewire_ohci" "sdhci_pci" ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-partlabel/nixos";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-partlabel/boot";
      fsType = "vfat";
    };
    "/home" = {
      device = "/dev/disk/by-partlabel/home";
      fsType = "ext4";
    };
  };

  swapDevices = [
    {
      device = "/dev/disk/by-partlabel/swap";
    }
  ];

  networking.interfaces.enp0s25 = lib.mkIf (! config.virtualisation ? qemu) {
    useDHCP = true;
    tempAddress = "disabled";
  };

  users.users.${me}.home = "/home/n2";

  system.stateVersion = "20.09";
}
