{ lib, this, config, pkgs, ... }: with lib; mkEnableModule [ "my-services" "soju" ] {
  services.soju = {
    enable = true;

    listen = [ "irc+insecure://${this.wireguard.ipv4}:6667" ];
  };
}
