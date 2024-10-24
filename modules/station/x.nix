{ lib, config, pkgs, ... }: with lib; {
  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
    tty = 1;
    autoRepeatDelay = 250;
    dpi = mkDefault 96;
    enableTearFree = true;
  };

  services.libinput = {
    enable = true;
    mouse.accelSpeed = "0.5";
    touchpad = {
      accelSpeed = "0.5";
      tapping = false;
    };
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
      if [[ ! $DISPLAY && $XDG_VTNR == ${toString config.services.xserver.tty} ]]; then
          export XDG_SESSION_TYPE=x11
          unset SHLVL_BASE
          exec systemd-cat -t xsession startx
      fi
    '';

    home.keyboard = with config.services.xserver.xkb; {
      inherit layout variant;
      options = splitString "," options;
    };

    home.pointerCursor = {
      package = pkgs.adwaita-icon-theme;
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
      vSync = ! config.services.xserver.enableTearFree;

      settings.unredir-if-possible = true; # reduces lag in fullscreen games

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
}
