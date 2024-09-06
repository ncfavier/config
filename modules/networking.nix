{ lib, this, config, pkgs, ... }: with lib; {
  config = mkMerge [
    {
      networking = {
        useNetworkd = true;
        tempAddresses = "disabled";

        hostName = mkIf (this ? hostname && this.hostname != null) this.hostname;
        hosts = { # remove default hostname mappings
          "127.0.0.2" = mkForce [];
          "::1" = mkForce [];
        };
        nameservers = mkDefault config.services.resolved.fallbackDns;

        firewall = {
          enable = true;
          logRefusedConnections = false;
          logReversePathDrops = true;
          rejectPackets = true;
          allowedUDPPorts = [ 5355 ]; # LLMNR
        };
      };

      services.resolved.fallbackDns = [
        "1.1.1.1#one.one.one.one"
        "1.0.0.1#one.one.one.one"
        "2606:4700:4700::1111#one.one.one.one"
        "2606:4700:4700::1001#one.one.one.one"
      ];

      services.nscd.enableNsncd = true;

      environment.systemPackages = with pkgs; [
        traceroute
        dnsutils
        ldns
        whois
        inetutils
        nethogs
        socat
        rsync
        iperf
        (writeShellScriptBin "port" ''
          usage() {
            printf 'usage: %s open|close tcp|udp|both PORT[:PORT]\n' "''${0##*/}" >&2
            exit "$@"
          }
          case $1 in
            -h) usage;;
            open) action=-I;;
            close) action=-D;;
            *) usage 1;;
          esac
          protocols=()
          [[ $2 == @(tcp|both) ]] && protocols+=(tcp)
          [[ $2 == @(udp|both) ]] && protocols+=(udp)
          (( ''${#protocols[@]} )) || usage 1
          port=$3
          [[ $port ]] || usage 1
          for proto in "''${protocols[@]}"; do
            for iptables in iptables ip6tables; do
              sudo "$iptables" "$action" nixos-fw -p "$proto" -m "$proto" --dport "$port" -j nixos-fw-accept
            done
          done
        '')
      ];

      programs.mtr.enable = true;

      security.wrappers.nethogs = {
        owner = "root";
        group = "root";
        capabilities = "cap_net_admin,cap_net_raw+p";
        source = "${pkgs.nethogs}/bin/nethogs";
      };
    }

    (mkIf this.isStation {
      networking.networkmanager = {
        enable = true;

        ensureProfiles = {
          environmentFiles = [ config.secrets.wireless.path ];
          profiles = {
            tsu = {
              connection.id = "tsu";
              connection.type = "wifi";
              wifi.ssid = "tsu";
              wifi-security.key-mgmt = "wpa-psk";
              wifi-security.psk = "$TSU_PSK";
            };
          };
        };
      };

      my.extraGroups = [ "networkmanager" ];

      hm.services.network-manager-applet.enable = true;

      systemd.network.wait-online.anyInterface = true;
    })
  ];
}
