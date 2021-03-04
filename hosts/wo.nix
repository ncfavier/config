{ pkgs, me, profilesPath, modulesPath, ... }: {
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"

    "${profilesPath}/wireguard-server.nix"
    "${profilesPath}/dns.nix"
    "${profilesPath}/nginx.nix"
    "${profilesPath}/mailserver.nix"
    "${profilesPath}/weechat"
    "${profilesPath}/syncthing.nix"
    "${profilesPath}/ulmaoc-topic.nix"
    "${profilesPath}/lambdabot.nix"
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
    size = 2048;
  } ];

  networking.interfaces.ens3.useDHCP = true;

  environment.systemPackages = with pkgs; [
    alacritty.terminfo
  ];

  users.users.${me}.hashedPassword = "$6$jvQ36QMw6kyzUjx$ApZlmPkvPyNAf2t51KpnocvMDo/1BubqCMR3q5jZD5OcM1awyAnTIgIeyaVl2XpAiNZPTouyuM1AOzBIGBu4m.";

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
