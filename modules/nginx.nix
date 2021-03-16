{ inputs, config, lib, here, my, syncedFolders, ... }: let
  uploadsRoot = "/run/nginx/uploads";
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
        ${my.domain} = ssl // {
          serverAliases = [ "www.${my.domain}" ];
          locations."/".root = inputs.${my.domain};
        };

        "up.${my.domain}" = ssl // {
          root = uploadsRoot;
          locations."/rice/".extraConfig = "autoindex on;";
          extraConfig = ''
            default_type text/plain;
          '';
        };

        "git.${my.domain}" = ssl // {
          locations."/".return = "301 https://github.com/${my.githubUsername}$request_uri";
        };

        default = {
          default = true;
          serverName = "_";
          useACMEHost = my.domain;
          addSSL = true;
          extraConfig = "return 444;";
        };
      };
    };

    systemd.services.nginx.serviceConfig.BindReadOnlyPaths = "${syncedFolders.uploads.path}:${uploadsRoot}";

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
