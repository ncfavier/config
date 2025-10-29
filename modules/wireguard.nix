{ lib, this, config, pkgs, ... }: with lib; let
  interface = config.networking.wireguard.interface;
  port = 500;
  enable = this ? wireguard;
  allExemptions = config.networking.wireguard.exemptions ++ config.networking.wireguard.extraExemptions;

  forwardPort = proto: port: map (addr: {
    inherit proto;
    sourcePort = port;
    destination = "${addr}:${toString port}";
  });
  forwardTcp = forwardPort "tcp";
  forwardUdp = forwardPort "udp";
  forwardBoth = port: addrs: forwardTcp port addrs ++ forwardUdp port addrs;
in {
  options.networking.wireguard = {
    interface = mkOption {
      type = types.str;
      default = "wg42";
    };

    subnetv4 = mkOption {
      type = types.str;
      default = "10.42.0.0/16";
    };

    subnetv6 = mkOption {
      type = types.str;
      default = "fd42::/16";
    };

    exemptions = mkOption {
      type = with types; listOf str;
      default = [
        "185.15.59.0/24" "2a02:ec80:300::/48" # Wikimedia
        "129.16.0.0/16" "2001:6b0::/32" # Chalmers
        "130.241.0.0/16" # Gothenburg University
        "40.126.0.0/18" "2603:1000::/25" # Microsoft
        "104.16.0.0/13" "172.64.0.0/13" # Stack Exchange (Cloudflare)
        "79.127.216.0/24" "89.187.169.0/24" "138.199.36.0/23" "169.150.247.0/24" # Bluesky CDN
      ];
    };

    # The AllowedIPs field has a length limit on WireGuard for Android, so having too many exemptions makes it go over the limit.
    # These exemptions are ignored by the script below.
    extraExemptions = mkOption {
      type = with types; listOf str;
      default = [
        "cache.nixos.org"
      ];
    };
  };

  config = mkMerge [
    (mkIf (enable && (this.isServer || this.isStation)) {
      networking.firewall.trustedInterfaces = [ interface ];
      systemd.network.wait-online.ignoredInterfaces = [ interface ];

      environment.systemPackages = [
        # Prints the AllowedIPs to be used on mobile phones (computers use a more advanced routing setup)
        (pkgs.pythonScriptWithDeps "wg-allowedips" (builtins.toFile "wg-allowedips.py" ''
          #!/usr/bin/env python3
          from netaddr import *
          from socket import *

          exempt = IPSet()
          for e in ${builtins.toJSON config.networking.wireguard.exemptions}:
            try:
              exempt.add(e)
            except AddrFormatError:
              exempt.update({a[0] for (_, _, _, _, a) in getaddrinfo(e, None)})

          all = IPSet({'0.0.0.0/0', '::/0'})
          private = IPSet({'0.0.0.0/8', '10.0.0.0/8', '127.0.0.0/8', '169.254.0.0/16', '172.16.0.0/12', '192.168.0.0/16', '240.0.0.0/4', 'fc00::/7', 'fe80::/10'})
          wg_private = IPSet(${with config.networking.wireguard; builtins.toJSON [ subnetv4 subnetv6 ]})
          allowed = all - (private | exempt) | wg_private

          print(', '.join(str(i) for i in allowed.iter_cidrs()))
        '') (ps: [ ps.netaddr ]))
      ];
    })

    (mkIf (enable && this.isServer) {
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
              endpoint = mkIf (m.ipv4 != []) "${head m.ipv4}:${toString port}";
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
          internalIPs = [ config.networking.wireguard.subnetv4 ];
          internalIPv6s = [ config.networking.wireguard.subnetv6 ];
          forwardPorts = forwardBoth 51413 [ my.machines.wo.wireguard.ipv4 "[${my.machines.wo.wireguard.ipv6}]" ]; # Transmission
        };
      };

      services.resolved.domains = [ interface ];
    })

    (mkIf (enable && this.isStation) (let
      wg-toggle = pkgs.shellScriptWith "wg-toggle" {
        deps = with pkgs; [ iproute2 jq systemd ];
      } ''
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
      '';
      wg-exempt = pkgs.shellScriptWith "wg-exempt" {
        deps = with pkgs; [ dnsutils iproute2 ];
      } ''
        PATH=/run/wrappers/bin:$PATH
        v4=() v6=() action=add
        for arg do
            if [[ $arg == -d ]]; then
                action=del
            elif [[ $arg == +([0-9]).+([0-9]).+([0-9]).+([0-9])?(/*) ]]; then
                v4+=("$arg")
            elif [[ $arg == *:*:* && $arg == +([[:xdigit:]:])?(/*) ]]; then
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
      '';
    in {
      networking.wg-quick.interfaces.${interface} = {
        privateKeyFile = config.secrets.wireguard.path;
        address = [ "${this.wireguard.ipv4}/16" "${this.wireguard.ipv6}/16" ];
        dns = [
          my.server.wireguard.ipv4 my.server.wireguard.ipv6
          interface # search domain
        ];
        peers = mapAttrsToList (_: m: {
          endpoint = "${head m.ipv4}:${toString port}";
          inherit (m.wireguard) publicKey;
          allowedIPs = if m.hostname == my.server.hostname
            then [ "0.0.0.0/0" "::/0" ]
            else [ "${m.wireguard.ipv4}/32" "${m.wireguard.ipv6}/128" ];
          persistentKeepalive = 21;
        }) (my.machinesThat (m: m.isServer && m ? wireguard));
        postUp = ''
          ${getExe wg-exempt} ${escapeShellArgs allExemptions}
        '';
        postDown = ''
          timeout 3s ${getExe wg-exempt} -d ${escapeShellArgs allExemptions} || true
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
