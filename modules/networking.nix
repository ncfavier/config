{ lib, here, pkgs, ... }: with lib; {
  options.networking = with types; {
    interfaces = mkOption {
      type = attrsOf (submodule {
        tempAddress = "disabled";
      });
    };
  };

  config = {
    networking = {
      hostName = mkIf (here != null) here.hostname;

      useDHCP = false;
      nameservers = [ "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001" ];
      hosts = { # remove default hostname mappings
        "127.0.0.2" = mkForce [];
        "::1" = mkForce [];
      };

      firewall = {
        enable = true;
        logRefusedConnections = false;
        rejectPackets = true;
      };
    };

    environment.systemPackages = with pkgs; [
      traceroute
      dnsutils
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
        case $2 in
          tcp|both) protocols+=(tcp);;&
          udp|both) protocols+=(udp);;
          *) usage 1;;
        esac
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
  };
}
