{ inputs, lib, this, config, ... }: with lib; let
  dns = inputs.dns.lib;
in {
  system.extraDependencies = collectFlakeInputs inputs.dns;

  services.nsd = {
    enable = true;
    interfaces = this.ipv4 ++ this.ipv6;
    ipTransparent = true;
    ratelimit.enable = true;

    zones = with dns.combinators; let
      soa = {
        SOA = {
          nameServer = "@";
          adminEmail = "dns@${my.domain}";
          serial = 0;
        };
        NS = [ "@" ];
      };
      aaaaa = {
        A = map a this.ipv4;
        AAAA = map aaaa this.ipv6;
      };
    in {
      "yoneda.ninja".data = dns.toString "yoneda.ninja" (soa // aaaaa // {
        TTL = 60;
        CAA = letsEncrypt "dns+caa@${my.domain}";
        subdomains."*" = aaaaa;
      });

      "grove.monade.li".data = dns.toString "grove.monade.li" (soa // aaaaa // {
        TTL = 60;
        TXT = [ "across old bark" "in the ancient glade" "it's always dark" "the quiet shade" ];
      });

      ${my.domain}.data = dns.toString my.domain (soa // aaaaa // {
        TTL = 60 * 60;

        MX = [ (mx.mx 10 "@") ];
        DKIM = [ {
          selector = "mail";
          p = config.lib.dkim.pk;
        } ];
        DMARC = [ {
          p = "quarantine";
          sp = "quarantine";
          rua = "mailto:dmarc@${my.domain}";
        } ];

        TXT = [
          (spf.strict [ "mx" ])
          "google-site-verification=yIwF9ILuYq54P151RraAs06TuJQMLZXKPRXSdn8FJWc"
        ];

        CAA = letsEncrypt "dns+caa@${my.domain}";

        SRV = [
          {
            proto = "tcp";
            service = "imaps";
            target = "@";
            port = 993;
          }
          {
            proto = "tcp";
            service = "submission";
            target = "@";
            port = 465;
          }
        ];

        subdomains = rec {
          "*" = aaaaa;

          github.CNAME = [ "${my.githubUsername}.github.io." ];
          glam = github;
          agda = github;
        };
      });
    };
  };

  services.unbound = {
    enable = true;
    localControlSocketPath = "/run/unbound/unbound.ctl";
    settings = {
      server = {
        tls-system-cert = true;
        interface = [
          "127.0.0.1" "::1"
          this.wireguard.ipv4 this.wireguard.ipv6
        ];
        access-control = [
          "127.0.0.0/8 allow" "::1/128 allow"
          "${config.networking.wireguard.subnetv4} allow" "${config.networking.wireguard.subnetv6} allow"
        ];
        private-address = with config.networking.wireguard; [
          subnetv4 subnetv6
        ];
        local-data = concatLists (mapAttrsToList (n: m: [
          ''"${n}.${config.networking.wireguard.interface}. A ${m.wireguard.ipv4}"''
          ''"${n}.${config.networking.wireguard.interface}. AAAA ${m.wireguard.ipv6}"''
        ]) (my.machinesWith "wireguard")) ++ [
          ''"fu.home. A 192.168.1.2"''
          ''"mo.home. A 192.168.1.3"''
          ''"tsu.home. A 192.168.1.4"''
          ''"no.home. A 192.168.1.5"''
          ''"printer.home. A 192.168.1.63"''
        ];
        local-data-ptr = concatLists (mapAttrsToList (n: m: [
          ''"${m.wireguard.ipv4} ${n}.${config.networking.wireguard.interface}."''
          ''"${m.wireguard.ipv6} ${n}.${config.networking.wireguard.interface}."''
        ]) (my.machinesWith "wireguard"));
      };
      forward-zone = [ {
        name = ".";
        forward-addr = config.services.resolved.fallbackDns;
        forward-tls-upstream = true;
      } ];
    };
  };

  my.extraGroups = [ config.services.unbound.group ];

  networking.nameservers = [ "127.0.0.1" "::1" ];

  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };
}
