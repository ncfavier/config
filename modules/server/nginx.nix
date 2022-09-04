{ inputs, lib, config, pkgs, ... }: with lib; let
  uploadsRoot = "/run/nginx/uploads";
  maxUploadSize = "256M";
in {
  system.extraDependencies = collectFlakeInputs inputs.www;

  services.nginx = {
    enable = true;
    package = pkgs.nginxMainline;
    enableReload = true;
    recommendedTlsSettings = true;
    serverNamesHashBucketSize = 128;
    commonHttpConfig = ''
      charset utf-8;
      types {
        text/plain sh csh tex latex rs tcl pl markdown md;
      }
      geo $internal {
        default 0;
        ${concatMapStrings (r: ''
        ${r} 1;
        '') (with config.networking.nat; internalIPs ++ internalIPv6s)}
      }
    '';

    virtualHosts = let
      ssl = {
        forceSSL = true;
        enableACME = true;
      };
    in {
      ${my.domain} = ssl // {
        root = inputs.www;
      };

      "www.${my.domain}" = ssl // {
        globalRedirect = my.domain;
      };

      "f.${my.domain}" = ssl // {
        root = uploadsRoot;
        locations."= /" = {
          extraConfig = ''
            if ($internal != 1) {
              return 403 "Nothing to see here, move along.\n";
            }
            fastcgi_pass unix:${config.services.phpfpm.pools.upload.socket};
            client_max_body_size ${maxUploadSize};
          '';
          fastcgiParams.SCRIPT_FILENAME = pkgs.writeText "upload.php" ''
            <?php
            if ($_SERVER['REQUEST_METHOD'] == 'POST') {
              header('Content-Type: text/plain');
              if (is_uploaded_file($_FILES['file']['tmp_name'])) {
                $url = exec('. /etc/set-environment; upload -r '.escapeshellarg($_FILES['file']['tmp_name']).' '.escapeshellarg(basename($_FILES['file']['name'])))."\n";
                if (isset($_POST['browser']))
                  header("Location: $url");
                else
                  echo $url;
              }
            } else { ?>
            <!doctype html>
            <meta name=viewport content="width=device-width, initial-scale=1">
            <title>Upload</title>
            <form method=post enctype=multipart/form-data>
              <input type=file name=file onchange="form.submit()">
              <input type=hidden name=browser value=1>
            </form>
            <?php }
          '';
        };
        locations."/".tryFiles = "$uri $uri/ /local$uri /local$uri/ =404";
        locations."= /favicon.ico".root = inputs.www;
        locations."/.st".extraConfig = "internal;";
        extraConfig = ''
          default_type text/plain;
          autoindex on;
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
}
