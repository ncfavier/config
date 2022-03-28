{ lib, this, config, pkgs, ... }: with lib; {
  options.networking = with types; {
    interfaces = mkOption {
      type = attrsOf (submodule {
        tempAddress = "disabled";
      });
    };
  };

  config = mkMerge [
    {
      networking = {
        useNetworkd = true;
        useDHCP = false; # specified per-interface instead

        hostName = mkIf (this ? hostname) this.hostname;
        hosts = { # remove default hostname mappings
          "127.0.0.2" = mkForce [];
          "::1" = mkForce [];
        };
        nameservers = mkDefault config.services.resolved.fallbackDns;

        firewall = {
          enable = true;
          logRefusedConnections = false;
          rejectPackets = true;
        };
      };

      services.resolved = {
        fallbackDns = [ "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001" ];
        domains = mkAfter [ my.domain ];
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
      nixpkgs.overlays = [ (pkgs: prev: {
        nethogs = prev.nethogs.overrideAttrs (o: {
          src = pkgs.fetchFromGitHub {
            owner = "raboof";
            repo = "nethogs";
            rev = "54f88038f6c6c44c9c642cac5dc90f21d4cb84b9";
            sha256 = "qnCphrVRh7bl+e5B6pbz32cCdmD8eiWbnHOWLGetmJQ=";
          };
          patches = [];
        });
      }) ];
    }

    (mkIf (this.isStation or false) {
      systemd.services.systemd-networkd-wait-online.serviceConfig.ExecStart = # TODO PR
        [ "" "${config.systemd.package}/lib/systemd/systemd-networkd-wait-online --any" ];

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
    })
  ];
}
