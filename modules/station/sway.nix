{ lib, config, pkgs, ... }: with lib; optionalAttrs false {
  hm = {
    wayland.windowManager.sway = {
      enable = true;
      config = {
        assigns = {
          "4:web" = [ { class = "^Firefox$"; } ];
        };
        bars = [];
        floating = {
          border = 0;
        };
        focus = {
          followMouse = false;
          forceWrapping = true;
        };
        fonts = [ "bitmap 8" ];
        gaps = {
          inner = 16;
          outer = 0;
        };
        input = {
          "*" = {
            repeat_delay = "250";
            xkb_layout = "fr,us,ru,gr";
            xkb_variant = "oss,,,";
            xkb_options = "grp:shifts_toggle,compose:menu,caps:escape_shifted_capslock";
          };
          "type:touchpad" = {
            pointer_accel = "0.6";
          };
        };
        bindkeysToCode = true;
        keybindings = let
          mod = config.hm.wayland.windowManager.sway.config.modifier;
        in {
          "${mod}+q" = "kill";
          "Alt+Tab" = "focus next";
          "Alt+Shift+Tab" = "focus prev";

          "${mod}+ampersand"  = "workspace number 1";
          "${mod}+eacute"     = "workspace number 2";
          "${mod}+quotedbl"   = "workspace number 3";
          "${mod}+apostrophe" = "workspace number 4";
          "${mod}+parenleft"  = "workspace number 5";
          "${mod}+minus"      = "workspace number 6";
          "${mod}+egrave"     = "workspace number 7";
          "${mod}+underscore" = "workspace number 8";
          "${mod}+ccedilla"   = "workspace number 9";
          "${mod}+z" = "workspace back_and_forth";
          "${mod}+Left" = "workspace prev";
          "${mod}+Shift+Left" = "move container to workspace prev";
          "${mod}+Right" = "workspace next";
          "${mod}+Shift+Right" = "move container to workspace next";

          "${mod}+Return" = "exec open terminal";
          "${mod}+c" = "exec open chat";
          "${mod}+w" = "exec open web";
          "${mod}+Shift+m" = "exec open mail";
          "${mod}+f" = "exec open files";
        };
        modifier = "Mod4";
        output."*" = {
          background = "${config.my.home}/.config/background fill";
        };
        window = {
          border = 0;
        };
      };
      wrapperFeatures.gtk = true;
      extraSessionCommands = ''
        export XDG_CURRENT_DESKTOP=sway
      '';
    };

    programs.bash.profileExtra = ''
      [[ ! $DISPLAY && $XDG_VTNR == 1 ]] && exec sway &> ~/.sway-log
    '';

    programs.waybar = {
      enable = true;
      settings = [
        {
          layer = "top";
          position = "top";
          height = 16;
          modules-left = [ "sway/workspaces" "sway/mode" "wlr/taskbar" ];
          modules-center = [ "sway/window" ];
          modules = {
            "sway/workspaces" = {
              disable-scroll = true;
              all-outputs = true;
            };
          };
        }
      ];
      systemd.enable = true;
    };

    programs.firefox.package = pkgs.firefox-wayland;
  };

  services.pipewire.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
    gtkUsePortal = true;
  };
}
