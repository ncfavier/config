{ lib, my, here, pkgs, ... }: {
  options.networking = with lib.types; {
    interfaces = lib.mkOption {
      type = attrsOf (submodule {
        tempAddress = "disabled";
      });
    };

    wan = {
      interface = lib.mkOption {
        type = str;
      };
      ipv4 = lib.mkOption {
        type = str;
      };
      ipv6 = lib.mkOption {
        type = str;
      };
    };
  };

  config = {
    networking = {
      hostName = here.hostname;

      useDHCP = false;
      nameservers = [ "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001" ];
      hosts = lib.mkForce {}; # remove default hostname -> localhost mapping

      firewall = {
        enable = true;
        logRefusedConnections = false;
        rejectPackets = true;
      };
    };

    environment.systemPackages = with pkgs; [
      traceroute
      mtr
      dnsutils
      whois
      nethogs
      socat
      rsync
    ];
  };
}
