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

      firewall.allowedUDPPorts = [ 67 ]; # DHCP

      nat = {
        enable = true;
        externalInterface = cfg.externalInterface;
        internalIPs = [ "192.168.42.0/24" ];
      };
    };

    systemd.network.networks."40-${cfg.internalInterface}" = {
      networkConfig = {
        ConfigureWithoutCarrier = true;
        DHCPServer = true;
      };
      dhcpServerConfig = {
        ServerAddress = "192.168.42.1/24";
        EmitDNS = false;
        EmitNTP = false;
        EmitTimezone = false;
      };
    };

    # Exempt forwarded packets from the WireGuard tunnel
    networking.wg-quick.interfaces.${config.networking.wireguard.interface} = let
      rule = "PREROUTING -m addrtype ! --dst-type LOCAL -j CONNMARK --set-mark $(wg show ${config.networking.wireguard.interface} fwmark)";
    in {
      postUp  = [ "iptables -t mangle -I ${rule}" ];
      preDown = [ "iptables -t mangle -D ${rule} || true" ];
    };
    nixpkgs.overlays = [ (self: super: {
      wireguard-tools = super.wireguard-tools.overrideAttrs (old: {
        patches = old.patches or [] ++ [ (self.fetchpatch {
          url = "https://github.com/ncfavier/wireguard-tools/commit/a67eb77a11be418f1a7699bbb28e8674a4d3fe89.patch";
          relative = "src";
          hash = "sha256-bLuSOGHs1toCHyFCaA4qkeyFj5vTjlaPITliMJownt0=";
        }) ];
      });
    }) ];
  };
}
