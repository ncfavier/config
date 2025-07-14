{ lib, config, ... }: with lib; {
  options.keys = {
    composeKey = mkOption {
      type = types.enum [ "ralt" "lwin" "lwin-altgr" "rwin" "rwin-altgr" "menu" "menu-altgr" "lctrl" "lctrl-altgr" "rctrl" "rctrl-altgr" "caps" "caps-altgr" "102" "102-altgr" "paus" "prsc" "sclk" ];
      default = "menu";
    };

    printScreenKey = mkOption {
      type = types.str;
      default = "Print";
    };
  };

  config = {
    i18n.defaultLocale = "en_GB.UTF-8";

    services.xserver.xkb = {
      layout = "fr-my,us,ru,gr";
      variant = ",,phonetic_azerty,";
      options = "grp:shifts_toggle,compose:${config.keys.composeKey},caps:escape";

      extraLayouts.fr-my = {
        languages = [ "fra" ];
        description = "Modified French layout";
        symbolsFile = builtins.toFile "fr-my" ''
          xkb_symbols "fr-my" {
            include "fr(oss)"
            key <TLDE> { [ grave, twosuperior ] };
            key <BKSL> { [ asterisk, dead_greek, dead_grave, dead_macron ] };
            key <AB08> { [ semicolon, period, multiply, U00B7 ] };
          };
        '';
      };
    };

    time.timeZone = "Europe/Stockholm";
  };
}
