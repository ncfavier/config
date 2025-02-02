{ lib, config, ... }: with lib; let
  cfg = config.services.mastodon;
  webDomain = "fedi.${my.domain}";
in mkEnableModule [ "my-services" "mastodon" ] {
  services.mastodon = {
    enable = true;
    localDomain = my.domain;
    extraConfig = {
      WEB_DOMAIN = webDomain;
      SINGLE_USER_MODE = "true";
      SMTP_OPENSSL_VERIFY_MODE = "none";
    };
    smtp.fromAddress = "mastodon@${my.domain}";

    configureNginx = false;
    smtp.createLocally = false;
  };

  services.nginx.virtualHosts = {
    ${webDomain} = {
      root = "${cfg.package}/public/";

      locations."/system/".alias = "/var/lib/mastodon/public-system/";

      locations."/" = {
        tryFiles = "$uri @proxy";
      };

      locations."@proxy" = {
        proxyPass = (if cfg.enableUnixSocket then "http://unix:/run/mastodon-web/web.socket" else "http://127.0.0.1:${toString(cfg.webPort)}");
        proxyWebsockets = true;
      };

      locations."/api/v1/streaming/" = {
        proxyPass = (if cfg.enableUnixSocket then "http://unix:/run/mastodon-streaming/streaming.socket" else "http://127.0.0.1:${toString(cfg.streamingPort)}/");
        proxyWebsockets = true;
      };
    };
    ${my.domain}.locations."/.well-known/webfinger".return = "301 https://${webDomain}$request_uri";
  };

  users.groups.${cfg.group}.members = [config.services.nginx.user];
}
