{ hardware, config, pkgs, ... }: {
  imports = with hardware; [
    notDetected
    common-cpu-intel-sandy-bridge
  ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 25;
        consoleMode = "max";
      };
    };

    kernelModules = [ "kvm-intel" ];
    initrd.availableKernelModules = [ "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
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
      neededForBoot = true;
    };
  };

  swapDevices = [ {
    device = "/swap";
    size = 4096;
  } ];

  networking = {
    interfaces.eno1.useDHCP = true;
    interfaces.wlp3s0.useDHCP = true;
    wireless.interfaces = [ "wlp3s0" ];
  };

  environment.systemPackages = with pkgs; [
    efibootmgr
    wpa_supplicant_gui
  ];

  services.xserver = {
    videoDrivers = [ "nvidia" ];
    screenSection = ''
      Option "metamodes" "nvidia-auto-select +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
    '';
  };

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.legacy_390;
    modesetting.enable = true;
  };

  hm.services.picom = {
    backend = "xrender";
    extraOptions = ''
      unredir-if-possible = false;
    '';
  };

  my.hashedPassword = "$6$rkmgv7prXu83oZqj$ydHDcvrUrd43Cvj38xDf6A2vQEAFIATX1O9XSRdUQbyHV/w6pc6qmAEmxZ4xAl3b3zgmVVyY5jg9QIaLndoAK/";

  services.syncthing.cert = builtins.toFile "syncthing-cert" ''
    -----BEGIN CERTIFICATE-----
    MIIBmjCCASCgAwIBAgIIRaL8rxe74e0wCgYIKoZIzj0EAwMwFDESMBAGA1UEAxMJ
    c3luY3RoaW5nMB4XDTE4MDcwMzIwMTExM1oXDTQ5MTIzMTIzNTk1OVowFDESMBAG
    A1UEAxMJc3luY3RoaW5nMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEjVHr6jb7E73k
    sJwqCw4AE2WoIV3WRZy4ITdg/XxP19N5reFdqyVfjp4LXIoZto8SWfbQ9pPlgY21
    eDTr/QIASnMI2Oc5Hcmb6ozv49AuQSef85UoSUU90YWkGNGODWuxoz8wPTAOBgNV
    HQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMAwGA1Ud
    EwEB/wQCMAAwCgYIKoZIzj0EAwMDaAAwZQIxAMcB86gR/XSiEVrDEQsDbRxn/kzJ
    vSzd4X9+RhQ+4i9dYYNPigt4xCxgewpyt0UmVAIwMf25wwJosKeBNFIH6CaEn/4g
    kjz2Vh63ayu5iLe7cOhUUIvmDuEW2wmxe/6Iz3LR
    -----END CERTIFICATE-----
  '';

  system.stateVersion = "21.05";
}
