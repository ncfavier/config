{ inputs, lib, this, config, ... }: with lib; let
  dns = inputs.nix-dns.lib;
in {
  services.nsd = {
    enable = true;
    interfaces = this.ipv4 ++ this.ipv6;
    ipTransparent = true;
    ratelimit.enable = true;

    zones.${my.domain}.data = with dns.combinators; let
      ips = {
        A = map a this.ipv4;
        AAAA = map aaaa this.ipv6;
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
        p = config.lib.dkim.pk;
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
          this.wireguard.ipv4 this.wireguard.ipv6
        ];
        access-control = [
          "127.0.0.0/8 allow" "::1/128 allow"
          "10.42.0.0/16 allow" "fd42::/16 allow"
        ];
        private-address = [
          "fd42::/16" "10.42.0.0/16"
        ];
        local-data = concatLists (mapAttrsToList (n: m: [
          ''"${n}. A ${m.wireguard.ipv4}"'' # TODO remove
          ''"${n}. AAAA ${m.wireguard.ipv6}"''
          ''"${n}.wg42. A ${m.wireguard.ipv4}"''
          ''"${n}.wg42. AAAA ${m.wireguard.ipv6}"''
        ]) my.machines) ++ [
          ''"fu.home. A 192.168.1.2"''
          ''"mo.home. A 192.168.1.3"''
          ''"no.home. A 192.168.1.5"''
          ''"tsu.home. A 192.168.1.4"''
          ''"printer.home. A 192.168.1.63"''
        ];
        local-data-ptr = concatLists (mapAttrsToList (n: m: [
          ''"${m.wireguard.ipv4} ${n}.wg42."''
          ''"${m.wireguard.ipv6} ${n}.wg42."''
        ]) my.machines);
      };
      forward-zone = [ {
        name = ".";
        forward-addr = [ "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001" ];
      } ];
    };
  };

  networking.nameservers = [ "127.0.0.1" "::1" ]; # use unbound for local queries

  networking.firewall = rec {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = allowedTCPPorts;
  };

  system.extraDependencies = [ inputs.nix-dns ];
}
