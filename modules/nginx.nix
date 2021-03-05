{ inputs, config, lib, domain, here, syncedFolders, ... }: let
  uploadsRoot = "/srv/uploads";
in {
  config = lib.mkIf here.isServer {
    services.nginx = {
      enable = true;
      recommendedTlsSettings = true;
      commonHttpConfig = ''
        charset utf-8;
        types {
          text/plain sh csh tex latex rs tcl pl markdown md;
        }
      '';

      virtualHosts = let
        ssl = {
          enableACME = true;
          forceSSL = true;
        };
      in {
        ${domain} = ssl // {
          serverAliases = [ "www.${domain}" ];
          locations."/".root = inputs.${domain};
        };

        "up.${domain}" = ssl // {
          root = uploadsRoot;
          locations."/rice/".extraConfig = "autoindex on;";
          extraConfig = ''
            default_type text/plain;
          '';
        };

        "git.${domain}" = ssl // {
          locations."/".return = "301 https://github.com/ncfavier$request_uri";
        };

        default = {
          default = true;
          serverName = "_";
          useACMEHost = domain;
          addSSL = true;
          extraConfig = "return 444;";
        };
      };
    };

    systemd.services.nginx.serviceConfig.BindReadOnlyPaths = "${syncedFolders.uploads.path}:${uploadsRoot}";

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
