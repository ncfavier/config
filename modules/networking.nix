{ lib, hostName, ... }: {
  options.networking.interfaces = lib.mkOption {
    type = with lib.types; attrsOf (submodule {
      tempAddress = "disabled";
    });
  };

  config.networking = {
    inherit hostName;

    nameservers = [ "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001" ];

    firewall = {
      enable = true;
      logRefusedConnections = false;
      rejectPackets = true;
    };
  };
}
