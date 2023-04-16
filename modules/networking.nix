{ lib, this, config, pkgs, ... }: with lib; {
  config = mkMerge [
    {
      networking = {
        useNetworkd = true;
        tempAddresses = "disabled";

        hostName = mkIf (this ? hostname) this.hostname;
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

    (mkIf (this.isStation or false) {
      networking.wireless = {
        enable = true;
        userControlled.enable = true;
        allowAuxiliaryImperativeNetworks = true;
        environmentFile = config.secrets.wireless.path;
        networks = {
          tsu.psk = "@TSU_PSK@";
        };
        fallbackToWPA2 = false;
      };

      environment.systemPackages = with pkgs; [ wpa_supplicant_gui ];

      systemd.network.networks."30-sncf" = {
        matchConfig.SSID = "_SNCF_WIFI_INOUI";
        DHCP = "yes";
        domains = [ "~sncf" ];
      };

      systemd.network.wait-online.anyInterface = true;
    })
  ];
}
