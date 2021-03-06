{ inputs, config, lib, domain, here, secrets, my, ... }: let
  cert = config.security.acme.certs.${domain};
in {
  imports = [ inputs.simple-nixos-mailserver.nixosModule ];

  config = lib.mkIf here.isServer {
    sops.secrets.dkim = {
      path = "/etc/dkim/${domain}.${config.mailserver.dkimSelector}.key";
      owner = config.services.opendkim.user;
      group = config.services.opendkim.group;
    };

    environment.etc."dkim/${domain}.${config.mailserver.dkimSelector}.txt".text = ""; # so the key isn't regenerated

    mailserver = {
      enable = true;
      enableImap = false;
      enableImapSsl = true;
      enableSubmission = false;
      enableSubmissionSsl = true;
      localDnsResolver = !config.networking.resolvconf.useLocalResolver;
      fqdn = domain;
      domains = [ domain ];
      certificateScheme = 1;
      certificateFile = "${cert.directory}/fullchain.pem";
      keyFile = "${cert.directory}/key.pem";
      dkimKeyDirectory = "/etc/dkim";
      loginAccounts.${my.email} = {
        hashedPassword = "$6$.ak/mUMQc5$6P0QSz5WZrzhEo56K1z6KAX.nMUfJMB6evxT4UD7p3f4cVp7nwnpVIagSyaFpUDiEM.rontDmltwT1hcT9oay0";
        aliases = [ "@${domain}" ];
      };
      lmtpSaveToDetailMailbox = "no";
    };

    systemd.services.opendkim.serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
  };
}
