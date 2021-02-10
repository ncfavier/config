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

  services.unbound = {
    enable = true;
    allowedAccess = [ "127.0.0.1/8" "::1/128" "10.42.0.1/16" "fd42::0:1/16" ];
    interfaces = [ "127.0.0.1" "::1" "10.42.0.1" "fd42::0:1" ];
    forwardAddresses = [ "1.1.1.1" "1.0.0.1" ];
    extraConfig = ''
      local-zone: "wo.wg42." redirect
      local-data: "wo.wg42.  A    10.42.0.1"
      local-data: "wo.wg42.  AAAA fd42::0:1"
      local-zone: "fu.wg42." redirect
      local-data: "fu.wg42.  A    10.42.1.1"
      local-data: "fu.wg42.  AAAA fd42::1:1"
      local-zone: "mo.wg42." redirect
      local-data: "mo.wg42.  A    10.42.2.1"
      local-data: "mo.wg42.  AAAA fd42::2:1"
      local-zone: "tsu.wg42." redirect
      local-data: "tsu.wg42. A    10.42.3.1"
      local-data: "tsu.wg42. AAAA fd42::3:1"
      local-data-ptr: "10.42.0.1 wo.wg42."
      local-data-ptr: "fd42::0:1 wo.wg42."
      local-data-ptr: "10.42.1.1 fu.wg42."
      local-data-ptr: "fd42::1:1 fu.wg42."
      local-data-ptr: "10.42.2.1 mo.wg42."
      local-data-ptr: "fd42::2:1 mo.wg42."
      local-data-ptr: "10.42.3.1 tsu.wg42."
      local-data-ptr: "fd42::3:1 tsu.wg42."
    '';
  };

  networking.search = [ "wg42" ];
  networking.nameservers = [ "127.0.0.1" "::1" ];

  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };
}
