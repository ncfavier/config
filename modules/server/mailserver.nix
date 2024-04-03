{ inputs, lib, config, ... }: with lib; {
  imports = [ inputs.simple-nixos-mailserver.nixosModules.default ];

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
    dkimKeyDirectory = "/etc/dkim";
    loginAccounts.${my.email} = {
      hashedPassword = "$2b$05$1YO805N1yn2vVM/c4K8nRuNix1ruHc4SJDDbWREgrcAaamxiqCYKS";
      aliases = [ "@${my.domain}" ];
    };
    lmtpSaveToDetailMailbox = "no";
    messageSizeLimit = 25 * 1024 * 1024;
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
        "FORGED_RECIPIENTS_2" {
          weight = 10;
        }
      }
    '';

    locals."settings.conf".text = ''
      forged_rcpt {
        rcpt = "znc";
        apply {
          FORCED_RECIPIENTS_2 = 100.0;
        }
        symbols [
          "FORGED_RECIPIENT_2"
        ]
      }
    '';
  };
}
