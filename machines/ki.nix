{
  identity = {
    isStation = true;
    wireguard = {
      ipv4 = "10.42.1.2";
      ipv6 = "fd42::1:2";
      publicKey = "uXNQlIA85TylU/PcHtrFTfJHjagXcYsG7UztgebU4hc=";
    };
    syncthing.id = "2IXUK3S-SC5ZNJF-UUPGWJZ-5MP646N-K3PZBIW-PL6OWZ4-NGXI6HU-I2YSYAC";
  };

  nixos = { hardware, lib, config, pkgs, ... }: with lib; {
    imports = with hardware; [
      notDetected
      common-cpu-amd
      common-cpu-amd-pstate
      common-gpu-amd
      common-pc-ssd
    ];

    boot = {
      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot = {
          enable = true;
          configurationLimit = 25;
        };
      };

      kernelPackages = pkgs.linuxPackages_latest;
      kernelModules = [ "kvm-amd" ];
      initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];

      initrd.luks.devices."nixos" = {
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
        options = [ "umask=0077" ];
      };
    };

    networking.wireless.interfaces = [ "wlp10s0" ];

    environment.systemPackages = with pkgs; [
      efibootmgr
      radeontop
    ];

    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
    hm.services.blueman-applet.enable = true;

    services.hardware.openrgb.enable = true;
    systemd.services.openrgb.postStart = ''
      ${getExe config.services.hardware.openrgb.package} --config ${config.hm.xdg.configHome}/OpenRGB -p default || true
    '';

    keys.composeKey = "rwin";
    keys.printScreenKey = "Insert";

    broadcasting.enable = true;

    services.xserver.videoDrivers = [ "amdgpu" ];

    my.hashedPassword = "$y$j9T$HVlzhk1CJa7IPyHjmHTFN.$c1go/wt0izX52Ej/EWtykusUCmqJLCXtvgXGvjcrHu8";

    services.syncthing.cert = builtins.toFile "syncthing-cert" ''
      -----BEGIN CERTIFICATE-----
      MIICHTCCAaOgAwIBAgIJAIiFIMuBBHvJMAoGCCqGSM49BAMCMEoxEjAQBgNVBAoT
      CVN5bmN0aGluZzEgMB4GA1UECxMXQXV0b21hdGljYWxseSBHZW5lcmF0ZWQxEjAQ
      BgNVBAMTCXN5bmN0aGluZzAeFw0yNDEwMTIwMDAwMDBaFw00NDEwMDcwMDAwMDBa
      MEoxEjAQBgNVBAoTCVN5bmN0aGluZzEgMB4GA1UECxMXQXV0b21hdGljYWxseSBH
      ZW5lcmF0ZWQxEjAQBgNVBAMTCXN5bmN0aGluZzB2MBAGByqGSM49AgEGBSuBBAAi
      A2IABKzijChL3fyXVLOpHM55LrqHvSugKa0Kk1CGMcgy8cv2fmVRuaqD3BWDvqv7
      F64kVv1Nk2bp9Uk0OI5Grs1NkwbnhgSzltbmCYt14S77AjW+gKZd1vWPE28AvCw6
      4ZI9FKNVMFMwDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggr
      BgEFBQcDAjAMBgNVHRMBAf8EAjAAMBQGA1UdEQQNMAuCCXN5bmN0aGluZzAKBggq
      hkjOPQQDAgNoADBlAjBoQwjVRAe4GoKURlTNUi4SphAch+pUMW/4SzMkFciG0bxz
      HqaMbjsXXA/NN/9aiLQCMQC0Lw0Ha2NmLZiwIukpZGk3vYP5odxymvtOk7NUuPWw
      X5aebMnRwUqYFqFQcTT4yDo=
      -----END CERTIFICATE-----
    '';

    system.stateVersion = "24.11";
  };
}
