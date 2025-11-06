{ lib, config, pkgs, ... }: with lib; let
  cursorTheme = {
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
  };
in {
  options.services.xserver.dpiScaleFactor = mkOption {
    type = types.float;
    readOnly = true;
    default = config.services.xserver.dpi / 96.0;
  };

  config = {
    services.xserver = {
      enable = true;
      autoRepeatDelay = 250;
      dpi = mkDefault 96;
      enableTearFree = mkDefault (builtins.head config.services.xserver.videoDrivers != "modesetting");
    };

    environment.variables = mkIf (config.services.xserver.dpiScaleFactor >= 2) {
      GDK_SCALE = toString config.services.xserver.dpiScaleFactor;
      GDK_DPI_SCALE = toString (1 / config.services.xserver.dpiScaleFactor);
      _JAVA_OPTIONS = "-Dsun.java2d.uiScale=${toString config.services.xserver.dpiScaleFactor}";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    };

    lib.x.scaleElectronApp = drv:
      if (config.services.xserver.dpiScaleFactor == 1) then drv
      else drv.override {
        commandLineArgs = "--force-device-scale-factor=${toString config.services.xserver.dpiScaleFactor}";
      };

    services.libinput = {
      enable = true;
      mouse.accelSpeed = mkDefault "0.5";
      touchpad = {
        accelSpeed = mkDefault "0.5";
        tapping = mkDefault false;
      };
    };

    lib.shellEnv = {
      inherit (config.services.xserver) dpi;
    };

    services.autorandr.enable = true;
    hm.xdg.configFile."autorandr/settings.ini".text = ''
      [config]
      skip-options=gamma
    '';

    my-programs.bspwm.enable = mkDefault true;

    hm = {
      home.keyboard = with config.services.xserver.xkb; {
        inherit layout variant;
        options = splitString "," options;
      };

      home.pointerCursor = cursorTheme // {
        size = config.lib.x.dpiScale cursorTheme.size;
        x11.enable = true;
        gtk.enable = true;
      };
      gtk.gtk4.cursorTheme = cursorTheme; # GTK 4 does its own DPI scaling

      home.packages = with pkgs; [
        xorg.xev
        arandr
        xdotool
      ];

      xsession.importedVariables = [
        "GDK_SCALE"
        "GDK_DPI_SCALE"
        "QT_AUTO_SCREEN_SCALE_FACTOR"
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
        vSync = ! config.services.xserver.enableTearFree;

        settings.unredir-if-possible = true; # reduces lag in fullscreen games

        # workaround for https://github.com/yshui/picom/issues/16#issuecomment-792739119
        fade = true;
        fadeSteps = [ 1 1 ];
        fadeDelta = 30;
      };

      services.redshift = {
        # enable = true;
        latitude = 48.0;
        longitude = 2.0;
      };
      systemd.user.services.redshift.Service.ExecStop =
        let terminate = "${pkgs.util-linux}/bin/kill $MAINPID";
        in "${terminate} ; ${terminate}"; # don't wait for the fade-out
    };
  };
}
