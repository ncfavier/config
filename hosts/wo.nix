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
      device = "/dev/disk/by-label/nixos";
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
    rxvt-unicode-unwrapped.terminfo
  ];

  services = {
    openssh.enable = true;
  };

  #systemd.user.services.tmux-weechat = {
  #  path = with pkgs; [ bash tmux ];
  #  script = ''
  #    tmux new-session -s weechat -n weechat -d -- bash -c 'date; exec bash'
  #    tmux set -t weechat status off
  #  '';
  #  serviceConfig = {
  #    Type = "forking";
  #    RemainAfterExit = true;
  #  };
  #  restartIfChanged = false;
  #};

  users.users.n = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD7KZW1RCBXJY1uDLbmaDUm50eshkv1rT8eK0JJXR3MfuCaJ/Kqrg547ZjczxED98Qy8A7d1BrIsOiKEoFVou+jCcjU19hlkQiMce3IZmYm0h6MOmZqB0MR6EGTlAgDfkiDMYqnAUGst4p2xqqmH/gM/UI2d5ZFrxAbK+PC4d7yMxs5QJkJ0buXRnbKL/LGRWwyUCV8UDzQ26kYufVyAhS2Iz2SvUSqca5BaJOzAPJ74CFScbICFK5nlsc2kHH35ZqK3f1Jxmbpi8ZwXUyxT+pFUClzY/s5H4w8c70ItvOyD3T0B+a8MF2Ft/c1kLFnHfYJd2FET+RZJQ5P+kXW+iZb n@monade.li"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDXcKmcpfziEqVXmhYIJyZ03DOb5x7wcf+FxYUWewWeBS5g1MfWKw/FH1H0EQeJf6z0epc/0oN50AViqe1zBnUChGGF2xjNzGEpDPjHg0MuEDMboXBHDBbBRjb31S4T7pkZ72cCV06+bilWdYnXc0E7ND81BakmuBJHFH3DvjYXudFdhwLEtmXAVIOdLBlIStY6ZMkHojPOjnfYrREa7PfllrH0dqwQI/v1dU7E6ZHV5OK631HhcAFhySlu4jdo890czsEqwTkMSrPrgVXiiQipvFAavZvqB53d9J36BkSeVO3meqz2x9N6puXL1A/f+a2Suc5mfMUayFm35lE3sw1h tsu"
    ];
  };

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;

    users.n = { config, ... }: {
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

      #xdg.configFile."systemd/user/default.target.wants/tmux-weechat.service".source =
      #  config.lib.file.mkOutOfStoreSymlink /etc/systemd/user/tmux-weechat.service;
    };
  };

  system.stateVersion = "21.03";
}
