{ inputs, config, lib, profilesPath, ... }: {
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
      mkVirtualHost = lib.recursiveUpdate {
        enableACME = true;
        forceSSL = true;
      };
    in {
      "monade.li" = mkVirtualHost {
        serverAliases = [ "www.monade.li" ];
        locations."/".root = inputs."monade.li";
      };

      "up.monade.li" = mkVirtualHost {
        locations."/".root = config.services.syncthing.declarative.folders.uploads.path;
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

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
