{ lib, my, here, config, secrets, pkgs, ... }: let
  interface = "wg42";
  port = 500;
in {
  config = lib.mkMerge [
    (lib.mkIf (here.isServer || here.isStation) {
      sops.secrets.wireguard = {
        format = "yaml";
        key = here.hostname;
      };
    })

    (lib.mkIf here.isServer {
      networking = {
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
            }) (lib.filterAttrs (_: m: !m.isServer) my.machines);
          };
        };

        firewall = {
          allowedUDPPorts = [ port ];
          trustedInterfaces = [ interface ];
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
          internalIPs = [ "10.42.0.0/16" ];
          internalIPv6s = [ "fd42::/16" ];
        };
      };
    })

    (lib.mkIf here.isStation {
      networking.wg-quick.interfaces.${interface} = {
        privateKeyFile = secrets.wireguard.path;
        address = [ "${here.wireguard.ipv4}/16" "${here.wireguard.ipv6}/16" ];
        dns = [ my.server.wireguard.ipv4 my.server.wireguard.ipv6 ];
        peers = [
          {
            endpoint = "${my.domain}:${toString port}";
            inherit (my.server.wireguard) publicKey;
            allowedIPs = [ "0.0.0.0/0" "::/0" ];
            persistentKeepalive = 21;
          }
        ];
      };

      environment.systemPackages = with pkgs; [
        (writeShellScriptBin "wg-toggle" ''
          ip46() { sudo ip -4 "$@"; sudo ip -6 "$@"; }
          fwmark=$(sudo wg show ${interface} fwmark) || exit
          cond=(not from all fwmark "$fwmark")
          if ip -j rule list "''${cond[@]}" | jq -e 'length > 0' > /dev/null; then
              ip46 rule del "''${cond[@]}"
          else
              ip46 rule add "''${cond[@]}" table "$fwmark"
          fi
        '')
        (writeShellScriptBin "wg-exempt" ''
          v4=() v6=() action=add
          for arg do
              if [[ $arg == -d ]]; then
                  action=del
              elif [[ $arg == +([0-9]).+([0-9]).+([0-9]).+([0-9]) ]]; then
                  v4+=("$arg")
              elif [[ $arg == *:*:* && $arg == +([[:xdigit:]:]) ]]; then
                  v6+=("$arg")
              else
                  v4+=($(${dnsutils}/bin/dig +short "$arg" A))
                  v6+=($(${dnsutils}/bin/dig +short "$arg" AAAA))
              fi
          done
          for ip in "''${v4[@]}"; do
              sudo ip rule "$action" from "$ip" lookup main
              sudo ip rule "$action" to "$ip" lookup main
          done
          for ip in "''${v6[@]}"; do
              sudo ip -6 rule "$action" from "$ip" lookup main
              sudo ip -6 rule "$action" to "$ip" lookup main
          done
        '')
      ];
    })
  ];
}
