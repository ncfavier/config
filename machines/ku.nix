{
  identity = {
    isServer = true;
    ipv4 = [ "152.53.123.186" ];
    ipv6 = [ "2a0a:4cc0:c0:4ccc::42" ];
    sshPort = 2242;
    wireguard = {
      ipv4 = "10.42.0.2";
      ipv6 = "fd42::0:2";
      publicKey = "Bh4e4iDqtG0KI2ey4FwFjQfKmJTnKsqMhbYh5eUx0ys=";
    };
    syncthing.id = "7ZXLXN2-LP3EWQZ-DSSPX4E-UHEIZIZ-45Z3R6J-IHFYDUP-N63R4R3-R5CGMQM";
  };

  nixos = { lib, this, config, modulesPath, pkgs, ... }: with lib; let
    interface = "ens3";
  in {
    imports = [
      "${modulesPath}/profiles/qemu-guest.nix"
    ];

    boot = {
      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot = {
          enable = true;
          configurationLimit = 3;
        };
      };

      kernelPackages = pkgs.linuxPackages_latest;
      initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];

      initrd.luks.devices.nixos = {
        device = "/dev/disk/by-partlabel/nixos";
        allowDiscards = true;
        bypassWorkqueues = true;
      };

      initrd.network = {
        enable = true;
        ssh = {
          enable = true;
          hostKeys = map (k: k.path) config.services.openssh.hostKeys;
        };
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
      size = 8 * 1024;
    } ];

    services.fstrim.enable = true;

    environment.systemPackages = with pkgs; [
      efibootmgr
    ];

    networking.defaultGateway6 = {
      inherit interface;
      address = "fe80::1";
    };
    networking.interfaces.${interface} = {
      useDHCP = true;
      ipv6.addresses = map (address: {
        inherit address;
        prefixLength = 64;
      }) this.ipv6;
    };

    networking.nat.externalInterface = interface;

    my.hashedPassword = "$y$j9T$gdhcWVYa8vkGfJpYE7XbQ.$QN9N0v0BZpFbAfMkqDoYN0O8KiTwXTN193kRowdrG0B";

    services.syncthing.cert = builtins.toFile "syncthing-cert" ''
      -----BEGIN CERTIFICATE-----
      MIICHTCCAaOgAwIBAgIJAIWEYSmi2c8yMAoGCCqGSM49BAMCMEoxEjAQBgNVBAoT
      CVN5bmN0aGluZzEgMB4GA1UECxMXQXV0b21hdGljYWxseSBHZW5lcmF0ZWQxEjAQ
      BgNVBAMTCXN5bmN0aGluZzAeFw0yNTAyMDEwMDAwMDBaFw00NTAxMjcwMDAwMDBa
      MEoxEjAQBgNVBAoTCVN5bmN0aGluZzEgMB4GA1UECxMXQXV0b21hdGljYWxseSBH
      ZW5lcmF0ZWQxEjAQBgNVBAMTCXN5bmN0aGluZzB2MBAGByqGSM49AgEGBSuBBAAi
      A2IABJjFwJ08JbC+TM+2roKBR2BgsL60H1fk0VhuCN3yj0j1xKgnGJes4UseroTU
      j4u+ZIIURfK6vsSVZ2CLHsq4xiTs46QulOgUjNOONhFGaCWYxwD59WGF15RJVYsu
      kpyXCqNVMFMwDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggr
      BgEFBQcDAjAMBgNVHRMBAf8EAjAAMBQGA1UdEQQNMAuCCXN5bmN0aGluZzAKBggq
      hkjOPQQDAgNoADBlAjApMKp5fFrfmXrsTMLSTAVPeWXRzMX3TY90qmyal7ucLeDG
      jPQbpAJ3MjGGbZItx84CMQD7rgA4l003CABvcTo3MahQMuaL2397KzEAyXeZLGyG
      Ma7GFmlNJQ9+bbgeXpKjN7A=
      -----END CERTIFICATE-----
    '';

    system.stateVersion = "22.05";

    # my-services.nginx.enable = true;
    # my-services.mailserver.enable = true;
    # my-services.weechat.enable = true;
    # my-services.bothendieck.enable = true;
    # my-services.lambdabot.enable = true;
  };
}
