{ inputs, lib, config, pkgs, ... }: with lib; let
  uploadsRoot = "/run/nginx/uploads";
  maxUploadSize = "100M";
in {
  services.nginx = {
    enable = true;
    package = pkgs.nginxMainline;
    enableReload = true;
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

      "f.${my.domain}" = ssl // {
        root = uploadsRoot;
        locations."=/" = {
          extraConfig = ''
            fastcgi_pass unix:${config.services.phpfpm.pools.upload.socket};
            client_max_body_size ${maxUploadSize};
            limit_except GET {
              ${concatMapStrings (r: ''
              allow ${r};
              '') (with config.networking.nat; internalIPs ++ internalIPv6s)}
              deny all;
            }
          '';
          fastcgiParams.SCRIPT_FILENAME = toString (pkgs.writeText "upload.php" ''
            <?php
            header('Content-Type: text/plain');
            if ($_SERVER['REQUEST_METHOD'] == 'POST') {
                if (is_uploaded_file($_FILES['file']['tmp_name']))
                    echo exec('. /etc/set-environment; upload -r '
                        .escapeshellarg($_FILES['file']['tmp_name']).' '
                        .escapeshellarg(basename($_FILES['file']['name']))
                    )."\n";
            } else
                echo "Nothing to see here, move along.\n";
          '');
        };
        locations."/".tryFiles = "$uri $uri/ /local$uri /local$uri/ =404";
        locations."/rice/".extraConfig = "autoindex on;";
        locations."=/live.iso".alias = let
          iso = inputs.self.nixosConfigurations.iso.config;
        in "${iso.system.build.isoImage}/iso/${iso.isoImage.isoName}";
        extraConfig = ''
          default_type text/plain;
        '';
      };

      "up.${my.domain}" = ssl // {
        globalRedirect = "f.${my.domain}";
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

  systemd.services.nginx.serviceConfig.BindReadOnlyPaths = [ "${config.synced.uploads.path}:${uploadsRoot}" ];

  services.phpfpm.pools.upload = {
    user = my.username;
    inherit (config.my) group;
    settings = {
      "listen.owner" = config.services.nginx.user;
      "pm" = "static";
      "pm.max_children" = 2;
      "catch_workers_output" = true;
    };
    phpOptions = ''
      upload_max_filesize = "${maxUploadSize}"
      post_max_size = "${maxUploadSize}"
    '';
  };

  systemd.services.phpfpm-upload.serviceConfig.ProtectHome = mkForce false;

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  nix.gcRoots = [ inputs.www ];
}
