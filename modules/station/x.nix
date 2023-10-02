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
      dpi = mkDefault 96;
    };

    lib.shellEnv = {
      inherit (config.services.xserver) dpi;
    };

    services.autorandr.enable = true;

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

      home.pointerCursor = {
        package = pkgs.gnome.adwaita-icon-theme;
        name = "Adwaita";
        size = 16;
        x11.enable = true;
      };

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
        "*color7" = foregroundAlt;
        "*color8" = backgroundAlt;
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
      };

      services.picom = {
        enable = mkDefault true;
        backend = mkDefault "glx";
        vSync = true; # the only reason i need picom...

        # workaround for https://github.com/yshui/picom/issues/16#issuecomment-792739119
        fade = true;
        fadeSteps = [ 1 1 ];
        fadeDelta = 30;
      };

      services.redshift = {
        enable = true;
        latitude = 48.0;
        longitude = 2.0;
      };
      systemd.user.services.redshift.Service.ExecStop =
        let terminate = "${pkgs.util-linux}/bin/kill $MAINPID";
        in "${terminate} ; ${terminate}"; # don't wait for the fade-out
    };
  };
}
