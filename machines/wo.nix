{
  identity = {
    isStation = true;
    wireguard = {
      ipv4 = "10.42.2.3";
      ipv6 = "fd42::2:3";
      publicKey = "fc1Vz7/KPNDQuqTiOyfIpunLIbSl/MYgxMETa9KBWFI=";
    };
    syncthing.id = "KUSNDTE-RO27UK3-HKBQK2W-R2HOLNS-IKTO4ZI-ZKQ7GHO-HQVCQYQ-K5X6WQT";
  };

  nixos = { hardware, lib, config, pkgs, ... }: with lib; {
    imports = with hardware; [
      notDetected
      framework-amd-ai-300-series
    ];

    services.fwupd.enable = true;

    boot = {
      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot = {
          enable = true;
          configurationLimit = 25;
          editor = false;
          consoleMode = "auto";
        };
      };

      kernelPackages = pkgs.linuxPackages_latest;
      kernelModules = [ "kvm-amd" ];
      initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" ];

      initrd.luks.devices.nixos = {
        device = "/dev/disk/by-partlabel/nixos";
        allowDiscards = true;
        bypassWorkqueues = true;
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
      size = 16 * 1024;
    } ];

    networking.wireless.interfaces = [ "wlp192s0" ];

    networking.sharing = {
      enable = false;
      internalInterface = "enp195s0f0u2";
      externalInterface = "wlp192s0";
    };

    environment.systemPackages = with pkgs; [
      efibootmgr
      amdgpu_top
      v4l-utils
    ];

    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
    hm.services.blueman-applet.enable = true;

    services.xserver.videoDrivers = [ "amdgpu" ];
    services.xserver.dpi = 192;
    services.xserver.upscaleDefaultCursor = true;
    fonts.fontconfig = {
      hinting.enable = false;
      subpixel.lcdfilter = "none";
    };

    services.autorandr = let
      eDP = "*";
      DisplayPort-1 = "*";
    in {
      profiles = {
        default = {
          fingerprint = { inherit eDP; };
          config = {
            eDP = {
              enable = true;
              mode = "2880x1920";
            };
          };
          hooks.postswitch.bspwm = ''
            bspc monitor DisplayPort-1 -r
          '';
        };
        hdmi = {
          fingerprint = { inherit eDP DisplayPort-1; };
          config = {
            eDP = {
              enable = true;
              primary = true;
              mode = "2880x1920";
            };
            DisplayPort-1 = {
              enable = true;
              mode = "1920x1080";
              position = "0x0";
            };
          };
        };
      };
    };

    services.libinput.touchpad.accelSpeed = "0.8";

    keys.composeKey = "rctrl";

    systemd.services.power-profiles-daemon = {
      serviceConfig.ExecStartPost = [
        "${getBin config.services.power-profiles-daemon.package}/bin/powerprofilesctl set power-saver"
      ];
    };

    battery.battery = "BAT1";
    battery.adapter = "ACAD";
    battery.fullAt = 99;

    services.fprintd.enable = true;

    broadcasting.enable = true;

    my.hashedPassword = "$y$j9T$iAwsXl5QOM5ku7mZGODkq.$CnAcwjvPNqPgUL7oyQ.luxOqq517KcrGkomfk.LH6H.";

    services.syncthing.cert = builtins.toFile "syncthing-cert" ''
      -----BEGIN CERTIFICATE-----
      MIICHjCCAaOgAwIBAgIJAKAiG0vUfpcyMAoGCCqGSM49BAMCMEoxEjAQBgNVBAoT
      CVN5bmN0aGluZzEgMB4GA1UECxMXQXV0b21hdGljYWxseSBHZW5lcmF0ZWQxEjAQ
      BgNVBAMTCXN5bmN0aGluZzAeFw0yNTA3MDUwMDAwMDBaFw00NTA2MzAwMDAwMDBa
      MEoxEjAQBgNVBAoTCVN5bmN0aGluZzEgMB4GA1UECxMXQXV0b21hdGljYWxseSBH
      ZW5lcmF0ZWQxEjAQBgNVBAMTCXN5bmN0aGluZzB2MBAGByqGSM49AgEGBSuBBAAi
      A2IABKqayorwBgQ4S6GHnZuWngsG1rZONgjn13MbFUXBoE1/lWWX/KnGF0GvbbPp
      rJrZFaT+mNX3YmUWh/1E4mYmhyKzQIqNIuaBUxjbGUIywo1AHewEsvUhCbQBkF1F
      Vm4LT6NVMFMwDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggr
      BgEFBQcDAjAMBgNVHRMBAf8EAjAAMBQGA1UdEQQNMAuCCXN5bmN0aGluZzAKBggq
      hkjOPQQDAgNpADBmAjEAkaB9BCrg7/MhoS1xxUB0Kww/CIygygEu7gk1rHfmSDDX
      EHkbBrQ4D4GPA6kaalBhAjEA/6WgAMK7s9mTs58v7zy3zeH1xrBXMkoQWwyvXDLg
      afIOg50rofZ8FxLzgCyG8Tk7
      -----END CERTIFICATE-----
    '';

    system.stateVersion = "25.11";
  };
}
