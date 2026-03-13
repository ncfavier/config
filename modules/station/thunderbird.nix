{ lib, config, pkgs, ... }: with lib; {
  hm = {
    programs.thunderbird = {
      enable = true;
      package = pkgs.thunderbird-esr-bin;

      profiles.default = {
        isDefault = true;
        settings = {
          "mailnews.localizedRe" = "Sv,SV"; # https://kb.mozillazine.org/Reply_indicators
        };
        extensions = attrVals [
          "dictionnaire-français1"
          "urgentmail"
          "tbsync"
          "eas-4-tbsync"
          "provider-for-google-calendar"
        ] pkgs.nur.repos.rycee.thunderbird-addons;
      };
    };
  };
}
