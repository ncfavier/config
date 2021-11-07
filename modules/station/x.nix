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
    };

    nixpkgs.overlays = [ (self: super: {
      picom-flicker-workaround = self.stdenv.mkDerivation {
        name = "picom-flicker-workaround";
        src = self.fetchFromGitHub {
          owner = "mphe";
          repo = "picom-flicker-workaround";
          rev = "fb484bdfac73444daea93e711d5c929f3767c0de";
          sha256 = "aeiN7C8XtbF+Hbt0VeVIgTskv2fCIsij173q28uPEpE=";
        };
        nativeBuildInputs = with self.xorg; [ libX11 libXScrnSaver ];
        makeFlags = [ "PREFIX=$(out)" ];
      };
    }) ];

    hm = {
      xsession = {
        enable = true;
        scriptPath = ".xinitrc";

        importedVariables = [ "PATH" ];
        numlock.enable = true;
        initExtra = ''
          [[ -f ~/.fehbg ]] && ~/.fehbg &
          ${pkgs.xorg.xset}/bin/xset -b
          ${pkgs.picom-flicker-workaround}/bin/xssstart pkill -usr1 picom &
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
        xlibs.xev
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
      };
    };
  };
}
