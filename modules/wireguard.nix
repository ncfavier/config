{ config, lib, hostName, domain, here, secrets, ... }: let
  interface = "wg42";
  port = 500;
  server = config.machines.wo; # TODO abstract
in {
  sops.secrets.wireguard = {
    format = "json";
    key = hostName;
  };

  networking = lib.mkMerge [
    (lib.mkIf here.isServer {
      wireguard = {
        enable = true;
        interfaces.${interface} = {
          privateKeyFile = secrets.wireguard.path;
          ips = [ "${here.wireguard.ipv4}/16" "${here.wireguard.ipv6}/16" ];
          listenPort = port;
          allowedIPsAsRoutes = false;
          peers = lib.mapAttrsToList (_: m: {
            inherit (m.wireguard) publicKey;
            allowedIPs = [ "${m.wireguard.ipv4}/32" "${m.wireguard.ipv6}/128" ];
          }) (lib.filterAttrs (_: m: !m.isServer) config.machines);
        };
      };

      firewall = {
        trustedInterfaces = [ interface ];
        allowedUDPPorts = [ port ];
        extraCommands = ''
          ip46tables -P FORWARD DROP
          ip46tables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
          ip46tables -A FORWARD -i ${interface} -j ACCEPT
        '';
        extraStopCommands = ''
          ip46tables -P FORWARD ACCEPT
          ip46tables -F FORWARD
        '';
      };

      nat = {
        enable = true;
        enableIPv6 = true;
        externalInterface = "ens3"; # TODO abstract
        internalIPs = [ "10.42.0.0/16" ];
        internalIPv6s = [ "fd42::/16" ];
      };
    })

    (lib.mkIf (!here.isServer) {
      wg-quick.interfaces.${interface} = {
        privateKeyFile = secrets.wireguard.path;
        address = [ "${here.wireguard.ipv4}/16" "${here.wireguard.ipv6}/16" ];
        dns = [ server.wireguard.ipv4 server.wireguard.ipv6 ];
        peers = [
          {
            endpoint = "${domain}:${toString port}";
            inherit (server.wireguard) publicKey;
            allowedIPs = [ "0.0.0.0/0" "::/0" ];
            persistentKeepalive = 21;
          }
        ];
      };
    })
  ];
}
