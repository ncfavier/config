{ lib, ... }: with lib; {
  i18n.defaultLocale = "en_GB.UTF-8";

  services.xserver = {
    layout = "fr,us,ru,gr";
    xkbVariant = "oss,,phonetic_fr,";
    xkbOptions = "grp:shifts_toggle";
  };

  time.timeZone = "Europe/Paris";
}
