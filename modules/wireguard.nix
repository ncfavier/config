{ lib, this, config, pkgs, ... }: with lib; let
  interface = config.networking.wireguard.interface;
  port = 500;
in {
  options.networking.wireguard.interface = mkOption {
    type = types.str;
    default = "wg42";
  };

  config = mkMerge [
    (mkIf (this.isServer || this.isStation) {
      networking.firewall.trustedInterfaces = [ interface ];
      systemd.network.wait-online.ignoredInterfaces = [ interface ];
    })

    (mkIf this.isServer {
      networking = {
        wireguard = {
          enable = true;
          interfaces.${interface} = {
            privateKeyFile = config.secrets.wireguard.path;
            ips = [ "${this.wireguard.ipv4}/16" "${this.wireguard.ipv6}/16" ];
            listenPort = port;
            allowedIPsAsRoutes = false;
            peers = mapAttrsToList (_: m: {
              inherit (m.wireguard) publicKey;
              allowedIPs = [ "${m.wireguard.ipv4}/32" "${m.wireguard.ipv6}/128" ];
            }) (my.machinesWith "wireguard");
          };
        };

        firewall = {
          allowedUDPPorts = [ port ];
          extraCommands = ''
            ip46tables -A FORWARD -i ${interface} -j ACCEPT
            ip46tables -A FORWARD -o ${interface} -j ACCEPT
            ip46tables -P FORWARD DROP
          '';
          extraStopCommands = ''
            ip46tables -F FORWARD
            ip46tables -P FORWARD ACCEPT
          '';
        };

        nat = {
          enable = true;
          enableIPv6 = true;
          internalIPs = [ "10.42.0.0/16" ];
          internalIPv6s = [ "fd42::/16" ];
        };
      };

      services.resolved.domains = [ interface ];
    })

    (mkIf this.isStation (let
      wg-toggle = pkgs.shellScriptWith "wg-toggle" (builtins.toFile "wg-toggle" ''
        PATH=/run/wrappers/bin:$PATH
        ip46() { sudo ip -4 "$@"; sudo ip -6 "$@"; }
        fwmark=$(sudo wg show ${interface} fwmark) || exit
        if ip -j route list default dev ${interface} table "$fwmark" | jq -e 'length > 0' > /dev/null; then
            ip46 route del default dev ${interface} table "$fwmark"
            resolvectl domain ${interface} ${interface}
        else
            ip46 route add default dev ${interface} table "$fwmark"
            resolvectl domain ${interface} ${interface} '~.' # ~. means "use this interface exclusively"
        fi
      '') { deps = with pkgs; [ iproute2 jq systemd ]; };
      wg-exempt = pkgs.shellScriptWith "wg-exempt" (builtins.toFile "wg-exempt" ''
        PATH=/run/wrappers/bin:$PATH
        v4=() v6=() action=add
        for arg do
            if [[ $arg == -d ]]; then
                action=del
            elif [[ $arg == +([0-9]).+([0-9]).+([0-9]).+([0-9]) ]]; then
                v4+=("$arg")
            elif [[ $arg == *:*:* && $arg == +([[:xdigit:]:]) ]]; then
                v6+=("$arg")
            else
                v4+=($(dig +short "$arg" A | grep -v '^;'))
                v6+=($(dig +short "$arg" AAAA | grep -v '^;'))
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
      '') { deps = with pkgs; [ dnsutils iproute2 ]; };
      exceptions = [ "wikipedia.org" ];
    in {
      networking.wg-quick.interfaces.${interface} = {
        privateKeyFile = config.secrets.wireguard.path;
        address = [ "${this.wireguard.ipv4}/16" "${this.wireguard.ipv6}/16" ];
        dns = [
          my.server.wireguard.ipv4 my.server.wireguard.ipv6
          interface # search domain
        ];
        peers = [ {
          endpoint = "${my.domain}:${toString port}";
          inherit (my.server.wireguard) publicKey;
          allowedIPs = [ "0.0.0.0/0" "::/0" ];
          persistentKeepalive = 21;
        } ];
        postUp = ''
          ${getExe wg-exempt} ${escapeShellArgs exceptions}
        '';
        preDown = ''
          ${getExe wg-exempt} -d ${escapeShellArgs exceptions} || true
        '';
      };

      systemd.services."wg-quick-${interface}" = {
        requires = [ "nss-lookup.target" ];
        after = [ "nss-lookup.target" ];
      };

      environment.systemPackages = [ wg-toggle wg-exempt ];
    }))
  ];
}
