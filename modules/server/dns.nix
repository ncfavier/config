{ inputs, config, lib, here, my, ... }: let
  dns = inputs.nix-dns.lib;
in {
  services.nsd = {
    enable = true;
    interfaces = [ config.networking.wan.ipv4 config.networking.wan.ipv6 ];
    ipTransparent = true;
    ratelimit.enable = true;

    zones.${my.domain}.data = with dns.combinators; let
      ips = {
        A = [ (a config.networking.wan.ipv4) ];
        AAAA = [ (aaaa config.networking.wan.ipv6) ];
      };
    in dns.toString my.domain (ips // {
      TTL = 60 * 60;

      SOA = {
        nameServer = "@";
        adminEmail = my.emailFor "dns";
        serial = 0;
      };
      NS = [ "@" ];

      MX = [ (mx.mx 10 "@") ];
      DKIM = [ {
        selector = "mail";
        p = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC/MUKMp4lOoDhaeyIh5hzVNkr5eJ7GMekGRCvVMpSx2DWgUPg8UR68VT1ObmEAQZVDd696XdRNFgFJZuaGSTqcjPfGVq7e+DFVZcRZbISat8mlvOyuDe7J2EwZQxn3gup9hwbesfFPCY6V+ZMwLylT0j974xqJPxEvkebZ+DylUwIDAQAB"; # TODO move dkim pk to mailserver.nix
      } ];
      DMARC = [ {
        p = "quarantine";
        sp = "quarantine";
        rua = "mailto:${my.emailFor "dmarc"}";
      } ];

      TXT = [
        (spf.strict [ "mx" ])
        "google-site-verification=yIwF9ILuYq54P151RraAs06TuJQMLZXKPRXSdn8FJWc"
      ];

      CAA = letsEncrypt (my.emailFor "dns+caa");

      subdomains = rec {
        "*" = ips;
        github.CNAME = [ "${my.githubUsername}.github.io." ];
        glam = github;
      };
    });
  };

  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = [
          "127.0.0.1" "::1"
          here.wireguard.ipv4 here.wireguard.ipv6
        ];
        access-control = [
          "127.0.0.0/8 allow" "::1/128 allow"
          "10.42.0.0/16 allow" "fd42::/16 allow"
        ];
        private-address = [
          "fd42::/16" "10.42.0.0/16"
        ];
        local-data = lib.concatLists (lib.mapAttrsToList (n: m: [
          ''"${n}. A ${m.wireguard.ipv4}"''
          ''"${n}. AAAA ${m.wireguard.ipv6}"''
        ]) my.machines);
        local-data-ptr = lib.concatLists (lib.mapAttrsToList (n: m: [
          ''"${m.wireguard.ipv4} ${n}."''
          ''"${m.wireguard.ipv6} ${n}."''
        ]) my.machines);
      };
      forward-zone = [ {
        name = ".";
        forward-addr = config.networking.nameservers;
      } ];
    };
  };

  networking.firewall = rec {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = allowedTCPPorts;
  };
}
