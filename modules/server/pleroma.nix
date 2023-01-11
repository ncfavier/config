{ inputs, lib, config, pkgs, ... }: with lib; let
  port = 4000;
  staticDirectory = pkgs.runCommand "pleroma-static" {
    nativeBuildInputs = [ pkgs.jq ];
  } ''
    mkdir -p "$out/static/themes" "$out/images"
    ln -s ${builtins.toFile "block.txt" ''
      User-Agent: *
      Disallow: /
    ''} "$out/robots.txt"
    ln -s ${pkgs.fetchurl {
      url = "https://plthemes.vulpes.one/themes/untime/untime.json";
      hash = "sha256-KeayQYuVIcbFkPzLpoiRxzKn+MNYEpalCmnDB2Efd6w=";
    }} "$out/static/themes/untime.json"
    ln -s ${pkgs.fetchurl {
      url = "https://plthemes.vulpes.one/themes/simply-dark/simply-dark.json";
      hash = "sha256-kKoaix+KzGX88rhKfr73VUPU4eELvi7NPY7bfuFUDX4=";
    }} "$out/static/themes/simply-dark.json"
    jq '.untime = "/static/themes/untime.json" | ."simply-dark" = "/static/themes/simply-dark.json"' ${config.services.pleroma.package}/lib/pleroma-*/priv/static/static/styles.json > "$out/static/styles.json"
    ln -s ${inputs.www}/favicon.png "$out/"
    > "$out/images/banner.png"
  '';
  # TODO motd, tos, logo etc.
in mkEnableModule [ "pleroma" ] {
  secrets.pleroma = {
    owner = config.users.users.pleroma.name;
    group = config.users.groups.pleroma.name;
  };

  services.pleroma = {
    enable = true;
    secretConfigFile = config.secrets.pleroma.path;
    configs = [ ''
      import Config

      config :pleroma, Pleroma.Web.Endpoint,
        url: [host: "fedi.${my.domain}", scheme: "https", port: 443],
        http: [ip: {127, 0, 0, 1}, port: ${toString port}]

      config :pleroma, Pleroma.Web.WebFinger,
        domain: "${my.domain}"

      config :pleroma, :instance,
        name: "${my.domain}",
        email: "pleroma@${my.domain}",
        notify_email: "pleroma@${my.domain}",
        limit: 5000,
        registrations_open: false,
        invites_enabled: true

      config :pleroma, :shout, enabled: false

      config :pleroma, :media_proxy,
        enabled: false,
        redirect_on_failure: true

      config :pleroma, Pleroma.Repo,
        adapter: Ecto.Adapters.Postgres,
        username: "pleroma",
        database: "pleroma",
        hostname: "localhost"

      config :web_push_encryption, :vapid_details,
        subject: "mailto:pleroma@${my.domain}"

      config :pleroma, :database, rum_enabled: false
      config :pleroma, :instance, static_dir: "${staticDirectory}"
      config :pleroma, Pleroma.Uploaders.Local, uploads: "/var/lib/pleroma/uploads"

      config :pleroma, :frontend_configurations,
        pleroma_fe: %{
          theme: "untime",
          background: "/images/none.jpg"
        }

      config :pleroma, :http_security, sts: true

      config :pleroma, configurable_from_database: false
    '' ];
  };

  services.postgresql.enable = true;

  services.nginx.virtualHosts = {
    "fedi.${my.domain}" = {
      http2 = true;
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString port}";
        extraConfig = ''
          etag on;
          gzip on;

          add_header 'Access-Control-Allow-Origin' '*' always;
          add_header 'Access-Control-Allow-Methods' 'POST, PUT, DELETE, GET, PATCH, OPTIONS' always;
          add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type, Idempotency-Key' always;
          add_header 'Access-Control-Expose-Headers' 'Link, X-RateLimit-Reset, X-RateLimit-Limit, X-RateLimit-Remaining, X-Request-Id' always;
          if ($request_method = OPTIONS) {
            return 204;
          }
          add_header X-XSS-Protection "1; mode=block";
          add_header X-Permitted-Cross-Domain-Policies none;
          add_header X-Frame-Options DENY;
          add_header X-Content-Type-Options nosniff;
          add_header Referrer-Policy same-origin;
          add_header X-Download-Options noopen;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_set_header Host $host;

          client_max_body_size 16m;
        '';
      };
    };

    ${my.domain}.locations."/.well-known/host-meta".return = "301 https://fedi.${my.domain}$request_uri";
  };
}
