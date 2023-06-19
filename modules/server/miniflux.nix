{ lib, config, ... }: with lib; {
  nixpkgs.overlays = [ (self: super: {
    miniflux = super.miniflux.overrideAttrs (old: {
      patches = old.patches or [] ++ [ (self.fetchpatch {
        url = "https://github.com/miniflux/v2/pull/1912/commits/0ca372e2235ea7b47d32248ad4b9fa66fdfb56c8.patch";
        hash = "sha256-NrbzumUbyXcXhQlOsv40DWMgY6ZL3yObIsONSBWdg50=";
      }) ];
    });
  }) ];

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
