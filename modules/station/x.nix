{ lib, config, theme, pkgs, ... }: with lib; {
  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
    tty = 1;
    autoRepeatDelay = 250;
  };

  hm = {
    xsession = {
      enable = true;
      scriptPath = ".xinitrc";

      importedVariables = [ "PATH" ];
      numlock.enable = true;
      initExtra = with pkgs.xorg; ''
        [[ -f ~/.fehbg ]] && ~/.fehbg &
        ${xset}/bin/xset -b
        ${xmodmap}/bin/xmodmap -e 'keycode 49 = grave twosuperior'
      '';

      pointerCursor = {
        package = pkgs.gnome.adwaita-icon-theme;
        name = "Adwaita";
        size = 16;
      };
    };

    programs.bash.profileExtra = ''
      if [[ ! $DISPLAY && $XDG_VTNR == 1 ]]; then
          exec systemd-cat -t xsession startx
      fi
    '';

    home.keyboard = with config.services.xserver; {
      inherit layout;
      variant = xkbVariant;
      options = splitString "," xkbOptions;
    };

    home.packages = with pkgs; [
      arandr
      hsetroot
      xlibs.xev
    ];

    xresources.properties = with theme; {
      "*color0" = black;
      "*color1" = hot;
      "*color2" = cold;
      "*color3" = hot;
      "*color4" = cold;
      "*color5" = hot;
      "*color6" = cold;
      "*color7" = darkGrey;
      "*color8" = lightGrey;
      "*color9" = hot;
      "*color10" = cold;
      "*color11" = hot;
      "*color12" = cold;
      "*color13" = hot;
      "*color14" = cold;
      "*color15" = white;
      "*background" = background;
      "*foreground" = foreground;
      "*cursorColor" = foreground;
      "*font" = "xft:bitmap:pixelsize=10,xft:tewi:pixelsize=10,xft:Biwidth:pixelsize=12,xft:Twitter Color Emoji:size=10";
    };

    services.picom = {
      enable = true;
      vSync = true;
    };

    services.redshift = {
      enable = true;
      latitude = 48.0;
      longitude = 2.0;
      settings.redshift.fade = false;
    };
  };
}
