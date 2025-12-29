{ inputs, lib, config, ... }: with lib; mkEnableModule [ "my-services" "mailserver" ] {
  imports = [ inputs.simple-nixos-mailserver.nixosModules.default ];

  secrets.dkim = {
    path = "/etc/dkim/${my.domain}.${config.mailserver.dkimSelector}.key";
    owner = config.services.rspamd.user;
    group = config.services.rspamd.group;
  };

  lib.dkim.pk = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC/MUKMp4lOoDhaeyIh5hzVNkr5eJ7GMekGRCvVMpSx2DWgUPg8UR68VT1ObmEAQZVDd696XdRNFgFJZuaGSTqcjPfGVq7e+DFVZcRZbISat8mlvOyuDe7J2EwZQxn3gup9hwbesfFPCY6V+ZMwLylT0j974xqJPxEvkebZ+DylUwIDAQAB";

  mailserver = {
    enable = true;
    stateVersion = 3;
    enableImap = false;
    enableSubmission = true;
    enableImapSsl = true;
    enableSubmissionSsl = true;
    localDnsResolver = false;
    fqdn = my.domain;
    domains = [ my.domain ];
    x509.useACMEHost = config.mailserver.fqdn;
    dkimKeyDirectory = "/etc/dkim";
    loginAccounts.${my.email} = {
      hashedPassword = "$2b$05$1YO805N1yn2vVM/c4K8nRuNix1ruHc4SJDDbWREgrcAaamxiqCYKS";
      aliases = [ "@${my.domain}" ];
    };
    lmtpSaveToDetailMailbox = "no";
    messageSizeLimit = 25 * 1024 * 1024;
    rejectRecipients = map (x: "${x}@${my.domain}") [ "naim" "znc" ];
    rejectSender = [ "sales@headquarters-biz.cloud" ];
  };

  my.extraGroups = [ config.mailserver.vmailGroupName ];

  system.activationScripts.vmailPermissions = {
    deps = [ "users" ];
    text = ''
      chmod -R g=u ${config.mailserver.mailDirectory}
    '';
  };

  services.rspamd = {
    overrides."whitelist.conf".text = ''
      whitelist_from {
        zulip.com = true;
        zulipchat.com = true;
      }
    '';

    locals."groups.conf".text = ''
      symbols {
        "FORGED_RECIPIENTS" {
          weight = 10;
        }
      }
    '';
  };
}
