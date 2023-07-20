{ lib, pkgs, ... }: with lib; {
  i18n.defaultLocale = "en_GB.UTF-8";

  nixpkgs.overlays = [ (self: super: {
    xorg = super.xorg // {
      xkeyboardconfig_custom = (pkgs.pr 244174 "sha256-RMyrRCDi7BbkvU5IBI7dgQ5yHSatajZgcdDqHj1yPso=").xorg.xkeyboardconfig_custom; # TODO
    };
  }) ];

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
        };
      '';
    };
  };

  time.timeZone = "Europe/Paris";
}
