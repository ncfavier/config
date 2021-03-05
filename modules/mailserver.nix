{ inputs, config, lib, my, here, secrets, ... }: let
  cert = config.security.acme.certs.${config.mailserver.fqdn};
in {
  imports = [ inputs.simple-nixos-mailserver.nixosModule ];

  config = lib.mkIf here.isServer {
    sops.secrets.dkim = {
      path = "/etc/dkim/${config.mailserver.fqdn}.${config.mailserver.dkimSelector}.key";
      owner = config.services.opendkim.user;
      group = config.services.opendkim.group;
    };

    environment.etc."dkim/${config.mailserver.fqdn}.${config.mailserver.dkimSelector}.txt".text = ""; # so the key isn't regenerated

    mailserver = {
      enable = true;
      enableImap = false;
      enableImapSsl = true;
      enableSubmission = false;
      enableSubmissionSsl = true;
      localDnsResolver = !config.networking.resolvconf.useLocalResolver;
      fqdn = my.domain;
      domains = [ config.mailserver.fqdn ];
      certificateScheme = 1;
      certificateFile = "${cert.directory}/fullchain.pem";
      keyFile = "${cert.directory}/key.pem";
      dkimKeyDirectory = "/etc/dkim";
      loginAccounts.${my.email} = {
        hashedPassword = "$6$.ak/mUMQc5$6P0QSz5WZrzhEo56K1z6KAX.nMUfJMB6evxT4UD7p3f4cVp7nwnpVIagSyaFpUDiEM.rontDmltwT1hcT9oay0";
        aliases = [ "@${config.mailserver.fqdn}" ];
      };
      lmtpSaveToDetailMailbox = "no";
    };

    systemd.services.opendkim.serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
  };
}
