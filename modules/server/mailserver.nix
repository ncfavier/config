{ inputs, lib, config, ... }: with lib; {
  imports = [ inputs.simple-nixos-mailserver.nixosModule ];

  system.extraDependencies = collectFlakeInputs inputs.simple-nixos-mailserver;

  secrets.dkim = {
    path = "/etc/dkim/${my.domain}.${config.mailserver.dkimSelector}.key";
    owner = config.services.opendkim.user;
    group = config.services.opendkim.group;
  };

  lib.dkim.pk = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC/MUKMp4lOoDhaeyIh5hzVNkr5eJ7GMekGRCvVMpSx2DWgUPg8UR68VT1ObmEAQZVDd696XdRNFgFJZuaGSTqcjPfGVq7e+DFVZcRZbISat8mlvOyuDe7J2EwZQxn3gup9hwbesfFPCY6V+ZMwLylT0j974xqJPxEvkebZ+DylUwIDAQAB";

  mailserver = {
    enable = true;
    enableImap = false;
    enableSubmission = true;
    enableImapSsl = true;
    enableSubmissionSsl = true;
    localDnsResolver = false;
    fqdn = my.domain;
    domains = [ my.domain ];
    certificateScheme = "acme";
    certificateACMEConfigureNginx = false;
    dkimKeyDirectory = "/etc/dkim";
    loginAccounts.${my.email} = {
      hashedPassword = "$2b$05$1YO805N1yn2vVM/c4K8nRuNix1ruHc4SJDDbWREgrcAaamxiqCYKS";
      aliases = [ "@${my.domain}" ];
    };
    lmtpSaveToDetailMailbox = "no";
  };

  my.extraGroups = [ config.mailserver.vmailGroupName ];

  system.activationScripts.vmailPermissions = {
    deps = [ "users" ];
    text = ''
      chmod -R g=u ${config.mailserver.mailDirectory}
    '';
  };
}
