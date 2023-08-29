{ lib, config, ... }: with lib; let
  port = 7546;
in {
  services.ntfy-sh = {
    enable = true;
    settings = {
      listen-http = "localhost:${toString port}";
      behind-proxy = true;
      base-url = "https://ntfy.monade.li";
      auth-default-access = "deny-all";
    };
  };

  services.nginx.virtualHosts."ntfy.${my.domain}".locations."/" = {
    proxyPass = "http://${config.services.ntfy-sh.settings.listen-http}";
    proxyWebsockets = true;
  };
}
