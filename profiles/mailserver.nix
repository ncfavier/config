{ inputs, config, my, secretsPath, ... }: let
  cert = config.security.acme.certs."monade.li";
in {
  imports = [ inputs.simple-nixos-mailserver.nixosModule ];

  sops.secrets.mail = {
    sopsFile = secretsPath + "/mail";
    format = "binary";
  };

  mailserver = {
    enable = true;
    enableImap = false;
    enableImapSsl = true;
    enableSubmission = false;
    enableSubmissionSsl = true;
    localDnsResolver = false;
    fqdn = "monade.li";
    domains = [ "monade.li" ];
    certificateScheme = 1;
    certificateFile = "${cert.directory}/fullchain.pem";
    keyFile = "${cert.directory}/key.pem";
    loginAccounts.${my.email} = {
      hashedPasswordFile = config.sops.secrets.mail.path;
      aliases = [ "@monade.li" ];
    };
    lmtpSaveToDetailMailbox = "no";
  };
}
