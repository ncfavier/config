{
  i18n.defaultLocale = "en_GB.UTF-8";

  # TODO move
  services.xserver = {
    layout = "fr,us,ru,gr";
    xkbVariant = "oss,,,";
    xkbOptions = "grp:shifts_toggle,compose:menu,caps:escape_shifted_capslock";
  };

  time.timeZone = "Europe/Paris";
}
