{ lib, config, pkgs, ... }: with lib; let
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
    networking.wg-quick.interfaces.${config.networking.wireguard.interface} = let
      rule = "PREROUTING -m addrtype ! --dst-type LOCAL -j CONNMARK --set-mark $(wg show ${config.networking.wireguard.interface} fwmark)";
    in {
      postUp  = [ "iptables -t mangle -I ${rule}" ];
      preDown = [ "iptables -t mangle -D ${rule} || true" ];
    };
    nixpkgs.overlays = [ (self: super: {
      wireguard-tools = super.wireguard-tools.overrideAttrs (old: {
        src = pkgs.fetchFromGitHub {
          owner = my.githubUsername;
          repo = "wireguard-tools";
          rev = "rpfilter-doc";
          hash = "sha256-vxtxGI0kOUYj5otLicdVURni0wUewwbc68tFuukrI2A=";
        };
      });
    }) ];

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
