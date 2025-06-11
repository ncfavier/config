{ inputs, lib, this, config, pkgs, ... }: with lib; let
  uploadsRoot = "/run/nginx/uploads";
  workRoot = "/run/nginx/work";
  maxUploadSize = "256M";
in {
  options = {
    my-services.nginx.enable = mkEnableOption "nginx";

    services.nginx.virtualHosts = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        config = mkIf (name != "default") {
          forceSSL = mkDefault true;
          enableACME = mkDefault true;
        };
      }));
    };
  };

  config = mkIf config.my-services.nginx.enable {
    system.extraDependencies = collectFlakeInputs inputs.www;

    services.nginx = {
      enable = true;
      package = pkgs.nginxMainline;
      enableReload = true;
      recommendedTlsSettings = true;
      recommendedProxySettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      serverNamesHashBucketSize = 128;
      commonHttpConfig = ''
        charset utf-8;
        charset_types text/css;
        types {
          text/plain sh csh tex latex rs tcl pl markdown md;
        }
        geo $internal {
          default 0;
          ${concatMapStrings (r: ''
          ${r} 1;
          '') (with config.networking.nat; internalIPs ++ internalIPv6s ++ this.ipv4 ++ this.ipv6)}
        }
      '';

      virtualHosts = {
        ${my.domain} = {
          root = inputs.www;
          locations."= /favicon.ico".tryFiles = "/favicon.png =404";
          locations."= /glam.pdf".alias = "${workRoot}/l3-ens/internship-glam/report/report.pdf";
          locations."= /glam-slides.pdf".alias = "${workRoot}/l3-ens/internship-glam/report/slides.pdf";
          locations."= /focusing.pdf".alias = "${workRoot}/m1-ens/internship-linearlogic/report.pdf";
          locations."= /focusing-slides.pdf".alias = "${workRoot}/m1-ens/internship-linearlogic/slides.pdf";
        };

        "www.${my.domain}".globalRedirect = my.domain;

        "grove.${my.domain}" = {
          locations."/" = {
            extraConfig = ''
              fastcgi_pass unix:${config.services.phpfpm.pools.upload.socket};
            '';
            fastcgiParams.SCRIPT_FILENAME = pkgs.writeText "grove.php" ''
              <?php
              header("Content-Type: text/plain");
              $poem = array("across old bark", "in the ancient glade", "it's always dark", "the quiet shade");
              shuffle($poem);
              foreach ($poem as $line) {
                echo "$line\n";
              }
            '';
          };
        };

        "f.${my.domain}" = {
          root = uploadsRoot;
          locations."= /" = {
            extraConfig = ''
              if ($internal != 1) {
                return 301 $scheme://${my.domain};
              }
              fastcgi_pass unix:${config.services.phpfpm.pools.upload.socket};
              client_max_body_size ${maxUploadSize};
            '';
            fastcgiParams.SCRIPT_FILENAME = pkgs.writeText "upload.php" ''
              <?php
              if ($_SERVER['REQUEST_METHOD'] == 'POST') {
                header('Content-Type: text/plain');
                if (is_uploaded_file($_FILES['file']['tmp_name'])) {
                  $url = exec('. /etc/set-environment; upload -r '.(isset($_POST['keepname']) ? "" : '-u ').escapeshellarg($_FILES['file']['tmp_name']).' '.escapeshellarg(basename($_FILES['file']['name'])))."\n";
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
                <input type=file name=file onchange="form.submit()"><br>
                <input type=checkbox id=keepname name=keepname>
                <label for=keepname>Keep name?</label>
                <input type=hidden name=browser value=1>
              </form>
              <?php }
            '';
          };
          locations."/".tryFiles = "$uri $uri/ /local$uri /local$uri/ =404";
          locations."= /favicon.png".return = "301 https://${my.domain}/favicon.png";
          locations."= /favicon.ico".return = "301 https://${my.domain}/favicon.ico";
          locations."/.st".extraConfig = "internal;";
          extraConfig = ''
            default_type text/plain;
            autoindex on;
          '';
        };

        "up.${my.domain}".globalRedirect = "f.${my.domain}";

        "git.${my.domain}".globalRedirect = "github.com/${my.githubUsername}";

        # "yoneda.ninja".locations."/".return = "301 https://arxiv.org/pdf/1501.02503.pdf";

        default = {
          default = true;
          rejectSSL = true;
          extraConfig = "return 444;";
        };
      };
    };

    systemd.services.nginx.serviceConfig.BindReadOnlyPaths = [
      "${config.synced.my.path}/work:${workRoot}"
      "${config.synced.uploads.path}:${uploadsRoot}"
    ];

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
  };
}
