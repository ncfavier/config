{ inputs, ... }: let
  dns = inputs.dns.lib;
  ipv4 = "199.247.15.22";
  ipv6 = "2001:19f0:6801:413:5400:2ff:feff:23e0";
in {
  services.nsd = {
    enable = true;
    interfaces = [ ipv4 ipv6 ];
    ipTransparent = true;
    ratelimit.enable = true;

    zones."monade.li".data = with dns.combinators; let
      theHost = {
        A = [ (a ipv4) ];
        AAAA = [ (aaaa ipv6) ];
      };
      github.CNAME = [ "ncfavier.github.io." ];
    in dns.toString "monade.li" (theHost // {
      SOA = {
        nameServer = "@";
        adminEmail = "dns@monade.li";
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
          rua = "mailto:dmarc@monade.li";
        }
      ];

      TXT = [ (spf.strict [ "mx" ]) ];

      CAA = letsEncrypt "dns+caa@monade.li";

      subdomains = {
        "*" = theHost;
        inherit github;
        glam = github;
      };
    });
  };
}
