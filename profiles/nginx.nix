{ inputs, config, profilesPath, syncedFolders, ... }: let
  uploadsRoot = "/srv/uploads";
in {
  imports = [ "${profilesPath}/acme.nix" ];

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
      "monade.li" = ssl // {
        serverAliases = [ "www.monade.li" ];
        locations."/".root = inputs."monade.li";
      };

      "up.monade.li" = ssl // {
        root = uploadsRoot;
        locations."/rice".extraConfig = "autoindex on;";
        extraConfig = ''
          default_type text/plain;
        '';
      };

      "git.monade.li" = ssl // {
        locations."/".return = "301 https://github.com/ncfavier$request_uri";
      };

      default = {
        default = true;
        serverName = "_";
        useACMEHost = "monade.li";
        addSSL = true;
        extraConfig = "return 444;";
      };
    };
  };

  systemd.services.nginx.serviceConfig.BindReadOnlyPaths = "${syncedFolders.uploads.path}:${uploadsRoot}";

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
