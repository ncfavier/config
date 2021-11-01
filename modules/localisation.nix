{
  i18n.defaultLocale = "en_GB.UTF-8";

  services.xserver = {
    layout = "fr,us,ru,gr";
    xkbVariant = "oss,,phonetic_fr,";
    xkbOptions = "grp:shifts_toggle,compose:rctrl,caps:escape_shifted_capslock";
  };

  time.timeZone = "Europe/Paris";
}
