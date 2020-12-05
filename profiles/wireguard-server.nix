{ config, lib, inputs, secretsPath, ... }: let
  interface = "wg42";
  port = 500;
in {
  disabledModules = [ "services/networking/nat.nix" ];
  imports = [ "${inputs.nixpkgs}/nixos/modules/services/networking/nat.nix" ];

  sops.secrets.wireguard = {
    sopsFile = "${secretsPath}/wireguard.json";
    key = config.networking.hostName;
  };

  networking = {
    wireguard = {
      enable = true;
      interfaces.${interface} = {
        privateKeyFile = config.sops.secrets.wireguard.path;
        ips = [ "10.42.0.1/16" "fd42::0:1/16" ];
        listenPort = port;
        allowedIPsAsRoutes = false;
        peers = [
          {
            publicKey = "v1MDB6hEYKdBwdVN/rOnOGB82h3xTQpHwU3CAcctGWg=";
            allowedIPs = [ "10.42.1.1/32" "fd42::1:1/128" ];
          }
          {
            publicKey = "tsvrIdHACcHMhtaHQt2tVE+2FO1LMdtiAlSXPNMuHFc=";
            allowedIPs = [ "10.42.2.1/32" "fd42::2:1/128" ];
          }
          {
            publicKey = "fRJFAT9BrQW5Wis3Jxq3mTR66IF6YlhvcCtMmjm78kI=";
            allowedIPs = [ "10.42.3.1/32" "fd42::3:1/128" ];
          }
        ];
      };
    };

    hosts = {
      "10.42.0.1" = [ "wo" ];
      "fd42::0:1" = [ "wo" ];
      "10.42.1.1" = [ "fu" ];
      "fd42::1:1" = [ "fu" ];
      "10.42.2.1" = [ "mo" ];
      "fd42::2:1" = [ "mo" ];
      "10.42.3.1" = [ "tsu" ];
      "fd42::3:1" = [ "tsu" ];
    };

    firewall = {
      trustedInterfaces = [ interface ];
      allowedUDPPorts = [ port ];
      extraCommands = ''
        ip46tables -P FORWARD DROP
        ip46tables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        ip46tables -A FORWARD -i ${interface} -j ACCEPT
      '';
      extraStopCommands = ''
        ip46tables -P FORWARD ACCEPT
        ip46tables -F FORWARD
      '';
    };

    nat = {
      enable = true;
      enableIPv6 = true;
      externalInterface = "ens3";
      internalIPs = [ "10.42.0.0/16" ];
      internalIPv6s = [ "fd42::/16" ];
    };
  };
}
