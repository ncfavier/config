{ pkgsMine, ... }: let
  unicode15Locales = (pkgsMine "glibcLocales-unicode-15" "sha256-tomjrc051DQbjt2aNrmXltvwF407Z6aWV7mTVOAsstg=").glibcLocales; # FIXME
in {
  hm.disabledModules = [ "config/i18n.nix" ];

  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.glibcLocales = unicode15Locales;
  cachix.derivationsToPush = [ unicode15Locales ];

  services.xserver = {
    layout = "fr,us,ru,gr";
    xkbVariant = "oss,,phonetic_fr,";
    xkbOptions = "grp:shifts_toggle";
  };

  time.timeZone = "Europe/Paris";
}
