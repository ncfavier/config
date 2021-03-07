{ inputs, config, lib, here, my, ... }: let
  dns = inputs.nix-dns.lib;
in {
  config = lib.mkIf here.isServer {
    services.nsd = {
      enable = true;
      interfaces = [ config.networking.wan.ipv4 config.networking.wan.ipv6 ];
      ipTransparent = true;
      ratelimit.enable = true;

      zones.${my.domain}.data = with dns.combinators; let
        base = {
          A = [ (a config.networking.wan.ipv4) ];
          AAAA = [ (aaaa config.networking.wan.ipv6) ];
        };
        github.CNAME = [ "${my.githubUsername}.github.io." ];
      in dns.toString my.domain (base // {
        SOA = {
          nameServer = "@";
          adminEmail = my.emailFor "dns";
          serial = 2020120600;
        };

        NS = [ "@" ];

        MX = [ (mx.mx 10 "@") ];
        DKIM = [
          {
            selector = "mail";
            p = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC/MUKMp4lOoDhaeyIh5hzVNkr5eJ7GMekGRCvVMpSx2DWgUPg8UR68VT1ObmEAQZVDd696XdRNFgFJZuaGSTqcjPfGVq7e+DFVZcRZbISat8mlvOyuDe7J2EwZQxn3gup9hwbesfFPCY6V+ZMwLylT0j974xqJPxEvkebZ+DylUwIDAQAB";
          }
        ];
        DMARC = [
          {
            p = "quarantine";
            sp = "quarantine";
            rua = "mailto:${my.emailFor "dmarc"}";
          }
        ];

        TXT = [ (spf.strict [ "mx" ]) ];

        CAA = letsEncrypt (my.emailFor "dns+caa");

        subdomains = {
          "*" = base;
          inherit github;
          glam = github;
        };
      });
    };

    services.unbound = {
      enable = true;
      interfaces = [ "127.0.0.1" "::1" here.wireguard.ipv4 here.wireguard.ipv6 ];
      allowedAccess = [ "127.0.0.0/8" "::1/128" "10.42.0.0/16" "fd42::/16" ];
      forwardAddresses = config.networking.nameservers;
      extraConfig = ''
        private-address: fd42::/16
        private-address: 10.42.0.0/16
        ${lib.concatStrings (lib.mapAttrsToList (n: m: ''
          local-data: "${n}. AAAA ${m.wireguard.ipv6}"
          local-data: "v4.${n}. A ${m.wireguard.ipv4}"
          local-data-ptr: "${m.wireguard.ipv6} ${n}."
          local-data-ptr: "${m.wireguard.ipv4} v4.${n}."
        '') my.machines)}
      '';
    };

    networking.firewall = rec {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = allowedTCPPorts;
    };
  };
}
