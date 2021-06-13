{ inputs, config, my, ... }: let
  cert = config.security.acme.certs.${my.domain};
in {
  imports = [ inputs.simple-nixos-mailserver.nixosModule ];

  config = {
    sops.secrets.dkim = {
      path = "/etc/dkim/${my.domain}.${config.mailserver.dkimSelector}.key";
      owner = config.services.opendkim.user;
      group = config.services.opendkim.group;
    };

    environment.etc."dkim/${my.domain}.${config.mailserver.dkimSelector}.txt".text = ""; # so the key isn't regenerated

    lib.dkim.pk = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC/MUKMp4lOoDhaeyIh5hzVNkr5eJ7GMekGRCvVMpSx2DWgUPg8UR68VT1ObmEAQZVDd696XdRNFgFJZuaGSTqcjPfGVq7e+DFVZcRZbISat8mlvOyuDe7J2EwZQxn3gup9hwbesfFPCY6V+ZMwLylT0j974xqJPxEvkebZ+DylUwIDAQAB";

    mailserver = {
      enable = true;
      enableImap = false;
      enableImapSsl = true;
      enableSubmission = false;
      enableSubmissionSsl = true;
      localDnsResolver = false;
      fqdn = my.domain;
      domains = [ my.domain ];
      certificateScheme = 1;
      certificateFile = "${cert.directory}/fullchain.pem";
      keyFile = "${cert.directory}/key.pem";
      dkimKeyDirectory = "/etc/dkim";
      loginAccounts.${my.email} = {
        hashedPassword = "$6$.ak/mUMQc5$6P0QSz5WZrzhEo56K1z6KAX.nMUfJMB6evxT4UD7p3f4cVp7nwnpVIagSyaFpUDiEM.rontDmltwT1hcT9oay0";
        aliases = [ "@${my.domain}" ];
      };
      lmtpSaveToDetailMailbox = "no";
    };
  };
}
