{ inputs, config, pkgs, lib, here, my, syncedFolders, ... }: let
  uploadsRoot = "/run/nginx/uploads";
in {
  imports = [ "${inputs.nixos-nginx-reject-ssl}/nixos/modules/services/web-servers/nginx" ];
  disabledModules = [ "services/web-servers/nginx/default.nix" ];

  config = lib.mkIf here.isServer {
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
          root = inputs.${my.domain};
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

    systemd.services.nginx.serviceConfig.BindReadOnlyPaths = "${syncedFolders.uploads.path}:${uploadsRoot}";

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
