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
      hostName = here.hostname;

      useDHCP = false;
      nameservers = [ "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001" ];
      hosts = mkForce {}; # TODO remove $HOSTNAME → localhost mapping

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
