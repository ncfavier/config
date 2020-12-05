{
  networking = {
    nameservers = [ "1.1.1.1" "1.0.0.1" ];

    firewall = {
      enable = true;
      logRefusedConnections = false;
      rejectPackets = true;
    };
  };
}
