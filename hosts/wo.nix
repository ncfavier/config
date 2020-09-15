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
      programs = {
        bash = {
          enable = true;
          shellAliases = {
            config = "sudo nixos-rebuild --flake ~/config";
          };
        };

        readline = {
          enable = true;
          bindings = {
            "\\e[A" = "history-search-backward";
            "\\e[B" = "history-search-forward";
          };
        };

        vim = {
          enable = true;
          plugins = with pkgs.vimPlugins; [ vim-nix ];
          settings = {
            mouse = "a";
          };
        };

        git = rec {
          enable = true;
          package = pkgs.gitAndTools.gitFull;
          userName = "Naïm Favier";
          userEmail = "n@monade.li";
          signing = {
            key = userEmail;
            signByDefault = true;
          };
          aliases = {
            i = "init";
            s = "status";
            d = "diff";
            dh = "diff HEAD";
            dc = "diff --cached";
            do = "diff origin";
            b = "branch";
            a = "add";
            aa = "add -A";
            au = "add -u";
            c = "!git commit --allow-empty-message -m \"$*\" #";
            ca = "!git commit --allow-empty-message -am \"$*\" #";
            ce = "commit --edit";
            cf = "!git commit -m \"$(${pkgs.fortune}/bin/fortune -sn 60 | tr -s '[:space:]' '[ *]')\"";
            co = "checkout";
            r = "reset";
            p = "push";
            pa = "push --all";
            pl = "pull --rebase --autostash";
            cl = "clone";
            cl1 = "clone --depth=1";
            l = "log --graph --oneline";
            la = "log --graph --oneline --all";
          };
        };
      };

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
