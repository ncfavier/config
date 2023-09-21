{ lib, ... }: with lib; {
  i18n.defaultLocale = "en_GB.UTF-8";

  services.xserver = {
    layout = "fr-my,us,ru,gr";
    xkbVariant = ",,phonetic_fr,";
    xkbOptions = "grp:shifts_toggle";

    extraLayouts.fr-my = {
      languages = [ "fra" ];
      description = "Modified French layout";
      symbolsFile = builtins.toFile "fr-my" ''
        xkb_symbols "fr-my" {
          include "fr(oss)"
          key <TLDE> { [ grave, twosuperior ] };
          key <BKSL> { [ asterisk, dead_greek, dead_grave, dead_macron ] };
        };
      '';
    };
  };

  time.timeZone = "Europe/Paris";
}
