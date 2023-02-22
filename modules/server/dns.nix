{ inputs, lib, this, config, pkgs, ... }: with lib; let
  dns = inputs.dns.lib;
in {
  system.extraDependencies = collectFlakeInputs inputs.dns;

  nixpkgs.overlays = [ (self: super: {
    bind = (pkgs.rev "bea64c8d594d0074d17a4513a2d2d856b1b0fee0" "sha256-X7cClFjpVm5emaEg9eABeXvG6yx7HCoTIqOE04ICjxA=").bind;
  }) ];

  services.nsd = {
    enable = true;
    interfaces = this.ipv4 ++ this.ipv6;
    ipTransparent = true;
    ratelimit.enable = true;

    zones.${my.domain} = {
      dnssec = true; # TODO
      data = with dns.combinators; let
        here = {
          A = map a this.ipv4;
          AAAA = map aaaa this.ipv6;
        };
      in dns.toString my.domain (here // {
        TTL = 60 * 60;

        SOA = {
          nameServer = "@";
          adminEmail = "dns@${my.domain}";
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
          rua = "mailto:dmarc@${my.domain}";
        } ];

        TXT = [
          (spf.strict [ "mx" ])
          "google-site-verification=yIwF9ILuYq54P151RraAs06TuJQMLZXKPRXSdn8FJWc"
        ];

        CAA = letsEncrypt "dns+caa@${my.domain}";

        subdomains = rec {
          "*" = here;

          github.CNAME = [ "${my.githubUsername}.github.io." ];
          glam = github;
        };
      });
    };
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
          ''"${n}.${config.networking.wireguard.interface}. A ${m.wireguard.ipv4}"''
          ''"${n}.${config.networking.wireguard.interface}. AAAA ${m.wireguard.ipv6}"''
        ]) my.machines) ++ [
          ''"fu.home. A 192.168.1.2"''
          ''"mo.home. A 192.168.1.3"''
          ''"tsu.home. A 192.168.1.4"''
          ''"no.home. A 192.168.1.5"''
          ''"printer.home. A 192.168.1.63"''
        ];
        local-data-ptr = concatLists (mapAttrsToList (n: m: [
          ''"${m.wireguard.ipv4} ${n}.${config.networking.wireguard.interface}."''
          ''"${m.wireguard.ipv6} ${n}.${config.networking.wireguard.interface}."''
        ]) my.machines);
      };
      forward-zone = [ {
        name = ".";
        forward-addr = config.services.resolved.fallbackDns;
      } ];
    };
  };

  networking.nameservers = [ "127.0.0.1" "::1" ]; # use unbound for local queries; TODO fix useLocalResolver + resolved

  networking.firewall = rec {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = allowedTCPPorts;
  };
}
