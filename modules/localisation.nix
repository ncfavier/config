{
  hm.disabledModules = [ "config/i18n.nix" ];

  i18n.defaultLocale = "en_GB.UTF-8";

  services.xserver = {
    layout = "fr,us,gr,ru";
    xkbVariant = "oss,,,phonetic_fr";
    xkbOptions = "grp:shifts_toggle";
  };

  time.timeZone = "Europe/Paris";
}
