{ lib, config, ... }: with lib; let
  cfg = config.networking.sharing;
in {
  options.networking.sharing = {
    enable = mkEnableOption "Internet sharing (IPv4 only)";

    internalInterface = mkOption {
      type = types.str;
      example = "eth0";
    };

    externalInterface = mkOption {
      type = types.str;
      example = "wlan0";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      interfaces.${cfg.internalInterface} = {
        ipv4.addresses = [
          {
            address = "192.168.42.1";
            prefixLength = 24;
          }
        ];
      };

      nat = {
        enable = true;
        externalInterface = cfg.externalInterface;
        internalIPs = [ "192.168.42.0/24" ];
      };
    };

    systemd.network.networks."40-${cfg.internalInterface}".networkConfig.ConfigureWithoutCarrier = true;

    # Exempt forwarded packets from the WireGuard tunnel
    # TODO https://github.com/NixOS/nixpkgs/pull/194758
    networking.wg-quick.interfaces.${config.networking.wireguard.interface} = {
      postUp = [
        "iptables -t mangle -I PREROUTING -m addrtype ! --dst-type LOCAL -j CONNMARK --set-mark 0xca6c"
      ];
      preDown = [
        "iptables -t mangle -D PREROUTING -m addrtype ! --dst-type LOCAL -j CONNMARK --set-mark 0xca6c || true"
      ];
    };

    services.dhcpd4 = {
      enable = true;
      interfaces = [ cfg.internalInterface ];
      extraConfig = ''
        option routers 192.168.42.1;
        subnet 192.168.42.0 netmask 255.255.255.0 {
          range 192.168.42.20 192.168.42.100;
        }
      '';
    };
  };
}
