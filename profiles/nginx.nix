{ inputs, profilesPath, lib, my, ... }: {
  imports = [ "${profilesPath}/acme.nix" ];

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    commonHttpConfig = "charset utf-8;";

    virtualHosts = let
      mkVirtualHost = lib.recursiveUpdate {
        enableACME = true;
        forceSSL = true;
        extraConfig = "error_page 404 @404;";
        locations."@404".return = "404 '404 Not found'";
      };
    in {
      "monade.li" = mkVirtualHost {
        serverAliases = [ "www.monade.li" ];
        locations."/".root = inputs."monade.li";
      };

      "up.monade.li" = mkVirtualHost {
        locations."/".root = "${my.home}/uploads";
      };

      "git.monade.li" = mkVirtualHost {
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

  systemd.services.nginx.serviceConfig.ProtectHome = false;

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
