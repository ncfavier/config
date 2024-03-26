{ inputs, lib, config, ... }: with lib; let
  signature = "nix.monade.li:2Zgy59ai/edDBizXByHMqiGgaHlE04G6Nzuhx1RPFgo=";
in {
  secrets.nix-binary-cache = {};

  imports = [ inputs.nix-serve-ng.nixosModules.default ];

  services.nix-serve = {
    enable = true;
    bindAddress = "127.0.0.1";
    openFirewall = false;
    secretKeyFile = config.secrets.nix-binary-cache.path;
    extraParams = "--priority 41";
  };

  services.nginx.virtualHosts."nix.${my.domain}" = {
    locations."= /" = {
      return = ''200 "${signature}\n"'';
      extraConfig = ''
        add_header Content-Type text/plain;
      '';
    };
    locations."/".proxyPass = "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
  };
}
