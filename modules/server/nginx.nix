{ inputs, lib, config, pkgs, ... }: with lib; let
  uploadsRoot = "/run/nginx/uploads";
in {
  services.nginx = {
    enable = true;
    package = pkgs.nginxMainline;
    recommendedTlsSettings = true;
    commonHttpConfig = ''
      charset utf-8;
      types {
        text/plain sh csh tex latex rs tcl pl markdown md;
      }
    '';

    virtualHosts = let
      ssl = {
        forceSSL = true;
        enableACME = true;
      };
    in {
      ${my.domain} = ssl // {
        serverAliases = [ "www.${my.domain}" ];
        root = inputs.www;
      };

      "up.${my.domain}" = ssl // {
        root = uploadsRoot;
        locations."/rice/".extraConfig = "autoindex on;";
        extraConfig = ''
          default_type text/plain;
        '';
      };

      "git.${my.domain}" = ssl // {
        globalRedirect = "github.com/${my.githubUsername}";
      };

      default = {
        default = true;
        rejectSSL = true;
        extraConfig = "return 444;";
      };
    };
  };

  systemd.services.nginx.serviceConfig.BindReadOnlyPaths = "${config.synced.uploads.path}:${uploadsRoot}";

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
