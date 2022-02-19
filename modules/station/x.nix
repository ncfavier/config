{ lib, config, pkgs, ... }: with lib; {
  options.keys = {
    composeKey = mkOption {
      type = types.enum [ "ralt" "lwin" "lwin-altgr" "rwin" "rwin-altgr" "menu" "menu-altgr" "lctrl" "lctrl-altg" "rctrl" "rctrl-altg" "caps" "caps-altgr" "102" "102-altgr" "paus" "prsc" "sclk" ];
      default = "menu";
    };

    printScreenKey = mkOption {
      type = types.str;
      default = "Print";
    };
  };

  config = {
    services.xserver = {
      enable = true;
      displayManager.startx.enable = true;
      tty = 1;
      autoRepeatDelay = 250;
      xkbOptions = "compose:${config.keys.composeKey},caps:escape_shifted_capslock";
      libinput = {
        enable = true;
        mouse.accelSpeed = "0.5";
        touchpad = {
          accelSpeed = "0.5";
          tapping = false;
        };
      };
    };

    hm = {
      xsession = {
        enable = true;
        scriptPath = ".xinitrc";

        importedVariables = [ "PATH" ];
        numlock.enable = true;
        initExtra = ''
          [[ -f ~/.fehbg ]] && ~/.fehbg &
          ${pkgs.xorg.xset}/bin/xset -b
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

      systemd.user.services.setxkbmap.Service.ExecStartPost =
        "${pkgs.xorg.xmodmap}/bin/xmodmap -e 'keycode 49 = grave twosuperior'";

      home.packages = with pkgs; [
        xorg.xev
        arandr
        hsetroot
        xdotool
      ];

      xresources.properties = with config.theme; {
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

        # workaround for https://github.com/yshui/picom/issues/16#issuecomment-792739119
        fade = true;
        fadeSteps = [ "1" "1" ];
        fadeDelta = 30;

        # workaround for https://github.com/yshui/picom/issues/578
        extraOptions = ''
          use-damage = false;
        '';
      };

      services.redshift = {
        enable = true;
        latitude = 48.0;
        longitude = 2.0;
      };
    };
  };
}
