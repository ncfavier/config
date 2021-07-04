{
  i18n.defaultLocale = "en_GB.UTF-8";

  services.xserver = {
    layout = "fr,us,ru,gr";
    xkbVariant = "oss,,phonetic_fr,";
    xkbOptions = "grp:ctrls_toggle,compose:menu,caps:escape_shifted_capslock";
  };

  time.timeZone = "Europe/Paris";
}
