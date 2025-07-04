{ lib, config, pkgs, ... }: with lib; {
  hm = {
    programs.thunderbird = {
      enable = true;

      profiles.default = {
        isDefault = true;
        settings = {
          "mailnews.localizedRe" = "Sv,SV"; # https://kb.mozillazine.org/Reply_indicators
        };
        extensions = let
          inherit (pkgs.nur.repos.rycee.firefox-addons) buildFirefoxXpiAddon;
        in [
          (buildFirefoxXpiAddon rec {
            pname = "urgentmail";
            version = "1.5";
            url = "https://addons.thunderbird.net/user-media/addons/_attachments/987926/urgentmail-${version}-tb.xpi";
            sha256 = "NQwbnpQVLTMRiPmEVMSp7buwtLLCug/zJQTfXmk9sEg=";
            addonId = "mailAlert@einKnie";
            meta = with lib; {
              homepage = "https://github.com/einKnie/urgentMail";
              description = "Raise X11 urgent flag if new mail is received. This addon listens for incoming mails and causes the Thunderbird window to draw attention.";
              mozPermissions = [
                "messagesRead"
                "accountsRead"
                "storage"
              ];
              license = licenses.gpl3;
              platforms = platforms.all;
            };
          })
          (buildFirefoxXpiAddon rec {
            pname = "tbsync";
            version = "4.15";
            url = "https://addons.thunderbird.net/user-media/addons/_attachments/773590/tbsync-${version}-tb.xpi";
            sha256 = "gLRrG7NGrvFsNOLEzmMSfqeUoSDSQ3ihtBoJuc58/XM=";
            addonId = "tbsync@jobisoft.de";
            meta = with lib; {
              homepage = "https://github.com/jobisoft/TbSync";
              description = "TbSync is a central user interface to manage cloud accounts and synchronize their contact, task and calendar information with Thunderbird.";
              license = licenses.mpl20;
              platforms = platforms.all;
            };
          })
          (buildFirefoxXpiAddon rec {
            pname = "provider-for-google-calendar";
            version = "128.5.7";
            url = "https://addons.thunderbird.net/user-media/addons/_attachments/4631/provider_for_google_calendar-${version}-tb.xpi";
            sha256 = "utO5AIE+0muaLenEt1mVCfReyBzFT/Xe2ZENTDYlbJ0=";
            addonId = "{a62ef8ec-5fdc-40c2-873c-223b8a6925cc}";
            meta = with lib; {
              homepage = "https://github.com/kewisch/gdata-provider/wiki/FAQ";
              description = "Provider for Google Calendar connects Thunderbird with Google Calendar for full task sync, conference details, and scheduling support. It offers deeper integration than Thunderbird’s native support using Google’s official API.";
              mozPermissions = [
                "storage"
              ];
              license = licenses.mpl20;
              platforms = platforms.all;
            };
          })
          (buildFirefoxXpiAddon rec {
            pname = "provider-fur-exchange-activesync";
            version = "4.16";
            url = "https://addons.thunderbird.net/user-media/addons/_attachments/986338/provider_fur_exchange_activesync-${version}-tb.xpi";
            sha256 = "7T31TFWE/OKnw9+/IrC4+Vz7GAtaAS5ZdtIcnu6BtO0=";
            addonId = "eas4tbsync@jobisoft.de";
            meta = with lib; {
              homepage = "https://github.com/jobisoft/EAS-4-TbSync";
              description = "Add sync support for Exchange ActiveSync (EAS v2.5 & v14.0) accounts to TbSync";
              mozPermissions = [
                "notifications"
              ];
              license = licenses.mpl20;
              platforms = platforms.all;
            };
          })
        ];
      };
    };
  };
}
