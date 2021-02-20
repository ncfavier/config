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
    interfaces = [ "127.0.0.1" "::1" "10.42.0.1" "fd42::0:1" ];
    allowedAccess = [ "127.0.0.0/8" "::1/128" "10.42.0.0/16" "fd42::/16" ];
    forwardAddresses = [ "1.1.1.1" "1.0.0.1" ];
    extraConfig = ''
      private-address: 10.42.0.0/16
      private-address: fd42::/16
      local-data: "wo. AAAA fd42::0:1"
      local-data: "v4.wo. A 10.42.0.1"
      local-data: "fu. AAAA fd42::1:1"
      local-data: "v4.fu. A 10.42.1.1"
      local-data: "mo. AAAA fd42::2:1"
      local-data: "v4.mo. A 10.42.2.1"
      local-data: "tsu. AAAA fd42::3:1"
      local-data: "v4.tsu. A 10.42.3.1"
      local-data-ptr: "fd42::0:1 wo."
      local-data-ptr: "10.42.0.1 v4.wo."
      local-data-ptr: "fd42::1:1 fu."
      local-data-ptr: "10.42.1.1 v4.fu."
      local-data-ptr: "fd42::2:1 mo."
      local-data-ptr: "10.42.2.1 v4.mo."
      local-data-ptr: "fd42::3:1 tsu."
      local-data-ptr: "10.42.3.1 v4.tsu."
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };
}
