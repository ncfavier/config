{ hardware, here, pkgs, ... }: {
  imports = with hardware; [
    notDetected
    lenovo-thinkpad-t14s-amd-gen1
  ];

  # services.tlp.settings = {
  #   START_CHARGE_THRESH_BAT0 = 75;
  #   STOP_CHARGE_THRESH_BAT0 = 80;
  #   RESTORE_THRESHOLDS_ON_BAT = 1;
  # };

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 25;
        # consoleMode = "max";
      };
    };

    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-amd" ];
    initrd.availableKernelModules = [ "nvme" "ehci_pci" "xhci_pci" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];

    initrd.luks.devices.nixos = {
      device = "/dev/disk/by-partlabel/nixos";
      allowDiscards = true;
      bypassWorkqueues = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };
  };

  networking = {
    interfaces.enp2s0f0.useDHCP = true;
    # interfaces.wlp3s0.useDHCP = true;
    # dhcpcd.allowInterfaces = [ "enp0s26u1u1" "enp0s26u1u2" "enp0s20u1u2" ]; # USB interfaces
    # wireless = {
    #   enable = true;
    #   interfaces = [ "wlp3s0" ];
    #   userControlled.enable = true;
    #   allowAuxiliaryImperativeNetworks = true;
    # };
  };

  environment.systemPackages = with pkgs; [
    efibootmgr
    wpa_supplicant_gui
    v4l-utils
  ];

  # TODO https://nixos.org/manual/nixos/unstable/#sec-gpu-accel-opencl-amd

  services.xserver.libinput = {
    enable = true;
    touchpad = {
      # accelSpeed = "0.6";
      tapping = false;
    };
  };

  # TODO fingerprint sensor

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
}
