{
  identity = {
    isStation = true;
    wireguard = {
      ipv4 = "10.42.2.2";
      ipv6 = "fd42::2:2";
      publicKey = "mQe4b0adN/BDQUTAzc+0rZp8M+ZjV17ewEtBLRIdM0I=";
    };
    syncthing.id = "MN3PICD-LGLVMZ2-SSNK5CG-LXNWL5R-U2QMWNM-AIA4UAG-NQ5WT5Y-B3TKXQV";
  };

  nixos = { hardware, lib, pkgs, ... }: with lib; {
    imports = with hardware; [
      notDetected
      lenovo-thinkpad-t14s-amd-gen1
    ];

    services.fwupd.enable = true;
    systemd.timers.fwupd-refresh.enable = false; # https://github.com/NixOS/nixpkgs/issues/271834

    services.tlp.settings = {
      RUNTIME_PM_DENYLIST = "02:00.0"; # otherwise the Ethernet adapter doesn't work on battery mode
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 81;
      RESTORE_THRESHOLDS_ON_BAT = 1;
    };

    boot = {
      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot = {
          enable = true;
          configurationLimit = 25;
        };
      };

      kernelPackages = mkForce pkgs.linuxPackages_latest;
      kernelModules = [ "kvm-amd" ];
      initrd.availableKernelModules = [ "nvme" "ehci_pci" "xhci_pci" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];

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
      size = 8192;
    } ];

    networking.wireless.interfaces = [ "wlp3s0" ];

    networking.sharing = {
      enable = true;
      internalInterface = "enp2s0f0";
      externalInterface = "wlp3s0";
    };

    environment.systemPackages = with pkgs; [
      efibootmgr
      radeontop
      v4l-utils
    ];

    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    services.xserver.dpi = 120;

    keys.composeKey = "prsc";
    keys.printScreenKey = "XF86Favorites";

    # services.fprintd.enable = true;

    broadcasting.enable = true;

    my.hashedPassword = "$y$j9T$Z68zdBJVmsTe5BneXrjFH1$jGJpIx5jFgUo8FSjrAqh.O4daLKNsybkUPoWJawPcX.";

    services.syncthing.cert = builtins.toFile "syncthing-cert" ''
      -----BEGIN CERTIFICATE-----
      MIICHTCCAaOgAwIBAgIJAN36G61Lv2lfMAoGCCqGSM49BAMCMEoxEjAQBgNVBAoT
      CVN5bmN0aGluZzEgMB4GA1UECxMXQXV0b21hdGljYWxseSBHZW5lcmF0ZWQxEjAQ
      BgNVBAMTCXN5bmN0aGluZzAeFw0yMTEwMjkwMDAwMDBaFw00MTEwMjQwMDAwMDBa
      MEoxEjAQBgNVBAoTCVN5bmN0aGluZzEgMB4GA1UECxMXQXV0b21hdGljYWxseSBH
      ZW5lcmF0ZWQxEjAQBgNVBAMTCXN5bmN0aGluZzB2MBAGByqGSM49AgEGBSuBBAAi
      A2IABCHVJtspig0zthYj74Y9B0zcLRDWPaTJxtvsY0UufLuKDK3UtzKNeAY8Z35c
      PmjcN7tIqqOENTtemnFgkDk36WmJRRMw4YY0kGLTqEdqpmCNhRUxwQFQnMjrgv8K
      r13Xg6NVMFMwDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggr
      BgEFBQcDAjAMBgNVHRMBAf8EAjAAMBQGA1UdEQQNMAuCCXN5bmN0aGluZzAKBggq
      hkjOPQQDAgNoADBlAjEA+zIz9AZ+w1B3OIzjb8QviWpPo8xWSoHSJJjQu7dsE2Z+
      mN6999x5soD/i6P9pX/vAjB1jhur5Bsjp26h1lHzB7jvJCauH4/XWKwkDaH4VS1N
      O8cpIdmFMm03uszmurRQxe8=
      -----END CERTIFICATE-----
    '';

    system.stateVersion = "21.11";
  };
}
