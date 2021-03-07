{ pkgs, modulesPath, ... }: {
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/vda";
    };

    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
  };

  fileSystems."/" = {
    device = "LABEL=nixos";
    fsType = "ext4";
  };

  swapDevices = [ {
    device = "/swap";
    size = 6144;
  } ];

  networking.wan = {
    interface = "ens3";
    ipv4 = "199.247.15.22";
    ipv6 = "2001:19f0:6801:413:5400:2ff:feff:23e0";
  };

  networking.interfaces.ens3.useDHCP = true;

  environment.systemPackages = with pkgs; [
    alacritty.terminfo
  ];

  my.hashedPassword = "$6$jvQ36QMw6kyzUjx$ApZlmPkvPyNAf2t51KpnocvMDo/1BubqCMR3q5jZD5OcM1awyAnTIgIeyaVl2XpAiNZPTouyuM1AOzBIGBu4m.";

  services.syncthing.declarative.cert = builtins.toFile "syncthing-cert" ''
    -----BEGIN CERTIFICATE-----
    MIIBmzCCASCgAwIBAgIIZR/vpL1iGHwwCgYIKoZIzj0EAwIwFDESMBAGA1UEAxMJ
    c3luY3RoaW5nMB4XDTIwMTExMTAwMDAwMFoXDTQwMTEwNjAwMDAwMFowFDESMBAG
    A1UEAxMJc3luY3RoaW5nMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAE5jPi++Nycm5j
    PRvKzhRkHlw8Am1qLryxpBqFJBoeEvLtFdrBXr0JmcfbXX8htKw863cH6LX1A7G5
    8rYn/qEuquu/yawsBrU2jDRD+18H0Cz2SJkhR6ZbVIFI00ZwO3wzoz8wPTAOBgNV
    HQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMAwGA1Ud
    EwEB/wQCMAAwCgYIKoZIzj0EAwIDaQAwZgIxALy2BpsKfyvadr0T9dkikU/KPjiT
    Dg2P8CiEOW63UoGxZdgAeTQuFJDQ2IrRUvy8LQIxANrQBQ309xy3sf44pgah1PvZ
    BDS5RTdh3BYmC2aLyy2ocJM7ZA2bmaR5i6dH2YebPw==
    -----END CERTIFICATE-----
  '';

  system.stateVersion = "21.03";
}
