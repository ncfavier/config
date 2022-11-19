{ lib, this, ... }: with lib; optionalAttrs this.isServer {
  imports = attrValues (modulesIn ./.);

  networking.firewall.allowedTCPPorts = [
    25565 # minecraft
  ];
}
