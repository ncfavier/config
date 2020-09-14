{ pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot = {
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/vda";
    };

    initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/c4acae87-9dd9-4675-b5eb-2dd059955e8f";
      fsType = "ext4";
    };
  };

  swapDevices = [
    {
      device = "/swap";
      size = 1024;
    }
  ];

  networking = {
    interfaces.ens3.useDHCP = true;
  };

  security = {
    sudo.wheelNeedsPassword = false;
  };

  i18n = {
    defaultLocale = "en_GB.UTF-8";
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr-pc";
  };

  time = {
    timeZone = "Europe/Paris";
  };

  environment.systemPackages = with pkgs; [
    vim
  ];

  services = {
    openssh.enable = true;
  };

  users.users.n = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;

    users.n = {
      services = {
        gpg-agent = {
          enable = true;
          enableSshSupport = true;
          sshKeys = [ "D10BD70AF981C671C8EE4D288F23BAE560675CA3" ];
        };
      };
    };
  };

  system.stateVersion = "20.09";
}
