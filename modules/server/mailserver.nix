{ inputs, lib, config, ... }: with lib; let
  cert = config.security.acme.certs.${my.domain};
in {
  imports = [ inputs.simple-nixos-mailserver.nixosModule ];

  config = {
    secrets.dkim = {
      path = "/etc/dkim/${my.domain}.${config.mailserver.dkimSelector}.key";
      owner = config.services.opendkim.user;
      group = config.services.opendkim.group;
    };

    lib.dkim.pk = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC/MUKMp4lOoDhaeyIh5hzVNkr5eJ7GMekGRCvVMpSx2DWgUPg8UR68VT1ObmEAQZVDd696XdRNFgFJZuaGSTqcjPfGVq7e+DFVZcRZbISat8mlvOyuDe7J2EwZQxn3gup9hwbesfFPCY6V+ZMwLylT0j974xqJPxEvkebZ+DylUwIDAQAB";

    mailserver = {
      enable = true;
      localDnsResolver = false;
      fqdn = my.domain;
      domains = [ my.domain ];
      certificateScheme = 1;
      certificateFile = "${cert.directory}/fullchain.pem";
      keyFile = "${cert.directory}/key.pem";
      dkimKeyDirectory = "/etc/dkim";
      loginAccounts.${my.email} = {
        hashedPassword = "$2y$10$CBwz0/CVZ/N0w0yvSCBhoOvKR6J79zd42kdHPZtXwW44yglL.rfLa";
        aliases = [ "@${my.domain}" ];
      };
      lmtpSaveToDetailMailbox = "no";
    };

    my.extraGroups = [ config.mailserver.vmailGroupName ];

    nix.gcRoots = [ inputs.simple-nixos-mailserver ];
  };
}
