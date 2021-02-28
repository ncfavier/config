# TODO merge with wireguard-server
{ config, secretPath, secrets, ... }: let
  interface = "wg42";
  port = 500;
in {
  sops.secrets.wireguard = {
    sopsFile = secretPath "wireguard.json";
    format = "json";
    key = config.networking.hostName;
  };

  networking.wg-quick.interfaces.${interface} = {
    privateKeyFile = secrets.wireguard.path;
    address = [ "10.42.2.1/16" "fd42::2:1/16" ];
    dns = [ "10.42.0.1" "fd42::0:1" ];
    peers = [
      {
        endpoint = "monade.li:${toString port}";
        publicKey = "fzC/SGpGcIbH/DyHrPYIW+9aAm2h4CvHZZosBPEHDHA=";
        allowedIPs = [ "0.0.0.0/0" "::/0" ];
        persistentKeepalive = 21;
      }
    ];
  };
}
