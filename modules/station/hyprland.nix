{ inputs, lib, config, pkgs, ... }: with lib; {
  # programs.hyprland.enable = true;

  hm = {
    imports = [ inputs.hyprland.homeManagerModules.default ];

    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      recommendedEnvironment = true;
      extraConfig = ''
        input {
          kb_layout = ${config.services.xserver.layout}
          kb_variant = ${config.services.xserver.xkbVariant}
          kb_options = ${config.services.xserver.xkbOptions}
          repeat_delay = ${toString config.services.xserver.autoRepeatDelay}
          follow_mouse = 0
          sensitivity = ${config.services.xserver.libinput.mouse.accelSpeed}

          touchpad {
            tap-to-click = false
          }
        }

        general {
          gaps_out = ${toString config.theme.padding}
          gaps_in = ${toString (config.theme.padding / 2)}
          no_cursor_warps = true
          resize_on_border = true
        }

        decoration {
          drop_shadow = false
          blur = false
        }

        animations {
          enabled = false
        }

        misc {
          disable_hyprland_logo = true
          disable_splash_rendering = true
        }

        $mainMod = SUPER

        bind = $mainMod, return, exec, alacritty
        bind = $mainMod, escape, exit

        bindm = $mainMod, mouse:272, movewindow
        bindm = $mainMod, mouse:273, resizewindow

        exec-once = ${pkgs.swaybg}/bin/swaybg --image /home/n/pictures/horizontal/544.png
      '';
    };
  };
}

