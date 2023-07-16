{ lib, config, ... }: with lib; {
  secrets.miniflux = {};

  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.secrets.miniflux.path;
    config = {
      LISTEN_ADDR = "localhost:8072";
      BASE_URL = "https://flux.${my.domain}";
    };
  };

  services.nginx.virtualHosts."flux.${my.domain}".locations."/".proxyPass = "http://${config.services.miniflux.config.LISTEN_ADDR}";
}
