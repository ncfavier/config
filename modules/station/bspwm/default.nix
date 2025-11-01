{ lib, config, pkgs, ... }: with lib; let
  bspwm = config.hm.xsession.windowManager.bspwm.package;
  tty = 1;
in mkEnableModule [ "my-programs" "bspwm" ] {
  services.xserver = {
    displayManager.startx.enable = true;
  };

  hm = {
    systemd.user.targets.graphical-session-bspwm = {
      Unit = {
        Description = "bspwm session";
        BindsTo = [ "graphical-session.target" ];
        Requisite = [ "graphical-session.target" ];
      };
    };

    xsession.windowManager.bspwm = {
      enable = true;
      monitors.focused = [ "web" "mail" "chat" "files" "1" ];
      alwaysResetDesktops = false;
      settings = with config.theme; {
        focused_border_color = borderColor;
        normal_border_color = borderColorAlt;
        border_width = borderWidth;
        presel_feedback_color = foreground;
        window_gap = config.lib.x.dpiScale padding;
        borderless_monocle = true;
        gapless_monocle = true;
        initial_polarity = "second_child";
        pointer_action1 = "move";
        pointer_action2 = "resize_side";
        pointer_action3 = "resize_corner";
      };
      rules = {
        firefox = {
          desktop = "web";
          follow = true;
        };
        "thunderbird" = {
          desktop = "mail";
          follow = true;
        };
        "thunderbird-esr" = {
          desktop = "mail";
          follow = true;
        };
        "*:irc" = {
          desktop = "chat";
          follow = true;
          state = "pseudo_tiled";
        };
        Thunar = {
          desktop = "files";
          follow = true;
        };
        dolphin = {
          desktop = "files";
          follow = true;
        };
        "org.gnome.FileRoller:org.gnome.FileRoller:Extract" = {
          state = "floating";
          rectangle = "${toString (config.lib.x.dpiScale 1200)}x${toString (config.lib.x.dpiScale 800)}+${toString (config.lib.x.dpiScale 300)}+${toString (config.lib.x.dpiScale 100)}";
        };
      } // genAttrs [
        "feh"
        "imv"
        "mpv"
        "File-roller"
        "Lxappearance"
        "pavucontrol"
        "plattenalbum"
        "*:calendar"
        "Qemu-system-x86_64"
        "Gucharmap"
        "Xfd"
        "zenity"
      ] (_: { state = "floating"; });
      extraConfig = ''
        bspc desktop web -l monocle
        bspc desktop mail -l monocle
      '';
      startupPrograms = [
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "${config.systemd.package}/bin/systemctl --user start graphical-session-bspwm.target"
      ];
    };

    xdg.configFile."bspwm/bspwmrc".onChange = ''
      if [[ -v DISPLAY ]] && ${getBin pkgs.procps}/bin/pgrep bspwm > /dev/null; then
        ${bspwm}/bin/bspc wm -r
      fi
    '';

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
      if [[ ! $DISPLAY && $XDG_VTNR == ${toString tty} ]]; then
          export XDG_SESSION_TYPE=x11
          unset SHLVL_BASE
          exec systemd-cat -t xsession startx
      fi
    '';

    home.packages = with pkgs; [
      xdo
      (shellScriptWith "wm" {
        deps = [ xtitle ]; # not all dependencies listed
        completion = ''
          _wm() {
            local cur prev words cword
            _init_completion
            if (( cword == 1 )); then
              compreply -W 'launch focus-window focus-workspace move-window-to-workspace remove-workspace add-workspace lock quit'
            elif [[ ''${words[1]} == launch ]]; then
              compreply -W '-n terminal chat irc editor web browser mail files music video volume calendar wifi emoji'
            fi
          }
          complete -F _wm wm
        '';
      } (readFile ./wm.sh))
    ];

    services.sxhkd = {
      enable = true;
      keybindings = {
        "super + @r" =
          "${config.hm.xdg.configHome}/bspwm/bspwmrc";
        "super + {_,shift} + {_,ctrl} + {ampersand,eacute,quotedbl,apostrophe,parenleft,minus,egrave,underscore,ccedilla}" =
          "wm {focus-workspace,move-window-to-workspace} {_,^}{1-9}";
        "super + {_,shift} + {_,ctrl} + KP_{1-9}" =
          "wm {focus-workspace,move-window-to-workspace} {_,^}{1-9}";
        "super + {_,shift} + {button4,button5,Left,Right}" =
          "wm {focus-workspace,move-window-to-workspace} {prev,next,prev,next}";
        "super + {_,shift} + {a,z}" =
          "wm {focus-workspace,move-window-to-workspace} {any.urgent,last}";
        "super + ctrl + {_,shift} + z" =
          "wm {focus-workspace,move-window-to-workspace} last.occupied";
        "super + {plus,equal}" =
          "wm {add,remove}-workspace";
        "super + KP_{Add,Subtract}" =
          "wm {add,remove}-workspace";
        "super + {_,shift} + Tab" =
          "bspc desktop -l {next,prev}";
        "super + {Prior,Home}" =
          "bspc node -f @{parent,/}";
        "alt + {_,shift} + {_,ctrl} + Tab" =
          "bspc node -f {next,prev}.window{.local,_}";
        "super + {t,shift + t,s,l}" =
          "bspc node -t '~{tiled,pseudo_tiled,floating,fullscreen}'";
        "super + y" =
          "bspc node -g sticky";
        "super + h" =
          "bspc node -g hidden";
        "super + shift + h" =
          "bspc node any.hidden -g hidden=off; bspc node any.below -l normal";
        "super + less" =
          ''bspc node -l "$(bspc query -T -n | jq -r 'if .client.layer == "above" then "normal" else "below" end')"'';
        "super + greater" =
          ''bspc node -l "$(bspc query -T -n | jq -r 'if .client.layer == "below" then "normal" else "above" end')"'';
        "super + {_,shift} + q" =
          "bspc node -{c,k}";
        "super + ctrl + {Left,Down,Up,Right}" =
          "bspc node -p \\~{west,south,north,east}";
        "super + ctrl + BackSpace" =
          "bspc node -p cancel";
        "super + ctrl + {b,e}" =
          "bspc node -{B,E}";
        "super + ctrl + {_,shift} + r" =
          "bspc node @/ -R {90,270}";

        "super + shift + l" =
          "wm lock";
        "{super + Escape,XF86PowerOff}" =
          "power";
        "super + {_,alt} + question" =
          "{nixos,home-manager}-help";
        "super + {_,shift,ctrl} + d" =
          "dunstctl {close,close-all,set-paused toggle}";
        "super + grave" =
          "dunstctl history-pop";
        "super + alt + {space,Left,Right}" =
          "playerctl {play-pause,previous,next}";
        "super + alt + BackSpace" =
          "playerctld shift";
        "super + alt + {Down,Up,r,z,y,c,b,f,u}" =
          "mpc -q {volume -2,volume +2,repeat,random,single,stop,seek -3,seek +3,update}";
        "XF86Audio{Play,Prev,Next,Stop}" =
          "playerctl {play-pause,previous,next,stop";
        "{_,super + alt} + XF86Audio{Lower,Raise}Volume" =
          "{_,mpc} volume {-,+}2";
        "XF86AudioMute" =
          "volume toggle-deaf";
        "alt + XF86Audio{Lower,Raise}Volume" =
          "volume mic {-,+}2 && mic-notify";
        "alt + XF86AudioMute" =
          "volume toggle-mute && mic-notify";
        "XF86AudioMicMute" =
          "volume toggle-mute && mic-notify";
        "XF86MonBrightness{Down,Up}" =
          "backlight {-,+}";
        "{_,super} + {_,ctrl} + {_,alt} + {_,shift} + ${config.keys.printScreenKey}" =
          "shoot {_,-c} {_,-n} {_,-v} {_,-u}";
        "super + u" =
          "unicode-analyse";
        "super + shift + u" =
          "xsel -bo | upload -";
        "super + p" = # Framework Fn + F9 emits super + p
          "true";
        "super + {_,shift} + space" =
          "wm launch";
        "super + shift + p" =
          "rofi-pass";
        "super + asterisk" =
          "rofi -show calc";
        "super + o" =
          "wm launch emoji";
        "super + ctrl + Return" =
          "rofi -show ssh";
        "super + {_,shift} + Return" =
          "{_,BASH_STARTUP=@${my.server.hostname} new_instance=1} wm launch terminal";
        "super + {_,shift} + KP_Enter" =
          "{_,BASH_STARTUP=@${my.server.hostname} new_instance=1} wm launch terminal";
        "super + {_,shift} + {w,x,c,f,e,v,m}" =
          "wm launch {_,-n} {web,mail,chat,files,editor,video,music}";
        "super + ctrl + w" =
          "wm launch wifi";
        "super + alt + w" =
          "firefox -P work";
      };
    };

    xdg.configFile."sxhkd/sxhkdrc".onChange = ''
      ${getBin pkgs.procps}/bin/pkill ''${VERBOSE+-e} -USR1 -x sxhkd || true
    '';
  };

  programs.i3lock.enable = true;

  nixpkgs.overlays = [
    (_: prev: {
      bspwm = prev.bspwm.overrideAttrs (o: {
        patches = o.patches or [] ++ optional config.broadcasting.enable
          (pkgs.fetchpatch {
            # hide_by_moving, useful for switching workspaces while broadcasting a window
            # https://github.com/baskerville/bspwm/issues/478
            url = "https://github.com/ncfavier/bspwm/commit/9e84eaa6eebe7faff7c7d0d2a911ed6a0d0b0296.patch";
            hash = "sha256-2SDGO3Q+/VXtagoqipBjaP0F4pQQl3qam/uKDchZO3I=";
          });
      });
    })
  ];
}
