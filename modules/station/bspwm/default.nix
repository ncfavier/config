{ lib, config, pkgs, ... }: with lib; let
  bar = with pkgs; shellScriptWith "bar" ./bar.sh {
    deps = [
      config-cli lemonbar-xft xtitle xkb-switch trayer
    ];
  };
in mkEnableModule [ "my-programs" "bspwm" ] {
  services.xserver = {
    displayManager.startx.enable = true;
    tty = 1;
  };

  hm = {
    xsession.windowManager.bspwm = {
      enable = true;
      monitors.focused = [ "web" "mail" "chat" "files" "1" ];
      alwaysResetDesktops = false;
      settings = with config.theme; {
        focused_border_color = foreground;
        normal_border_color = foregroundAlt;
        presel_feedback_color = hot;
        border_width = borderWidth;
        window_gap = padding;
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
        thunderbird = {
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
      } // genAttrs [
        "feh"
        "imv"
        "mpv"
        "File-roller"
        "Lxappearance"
        "Pavucontrol"
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
        "${bar}/bin/bar" # ensure bspwmrc changes if bar.sh changes
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      ];
    };

    xdg.configFile."bspwm/bspwmrc".onChange = ''
      if [[ -v DISPLAY ]] && pgrep bspwm > /dev/null; then
        "$XDG_CONFIG_HOME"/bspwm/bspwmrc
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
      if [[ ! $DISPLAY && $XDG_VTNR == ${toString config.services.xserver.tty} ]]; then
          export XDG_SESSION_TYPE=x11
          unset SHLVL_BASE
          exec systemd-cat -t xsession startx
      fi
    '';

    home.packages = with pkgs; [
      xdo
      bar
      (shellScriptWith "wm" ./wm.sh { deps = [ xtitle ]; })
    ];

    programs.bash.initExtra = ''
      _wm() {
        local cur prev words cword
        _init_completion
        if (( cword == 1 )); then
          compreply -W 'go focus-window focus-workspace move-window-to-workspace remove-workspace add-workspace lock quit'
        elif [[ ''${words[1]} == go ]]; then
          compreply -W '-n terminal chat irc editor web browser mail files music video volume calendar wifi emoji'
        fi
      }
      complete -F _wm wm
    '';

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
          "bspc node any.hidden -g hidden=off";
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
          "volume toggle";
        "XF86AudioMicMute" =
          "volume toggle-mic";
        "XF86MonBrightness{Down,Up}" =
          "backlight {-,+}";
        "{_,super} + {_,ctrl} + {_,alt} + {_,shift} + ${config.keys.printScreenKey}" =
          "shoot {_,-c} {_,-n} {_,-v} {_,-u}";
        "super + p" =
          "xsel -bo | upload -";
        "super + shift + p" =
          "rofi-pass";
        "super + {_,shift,ctrl} + space" =
          "rofi -sidebar-mode -show-icons -modes drun,run,window -show {drun,drun,window}";
        "super + asterisk" =
          "rofi -show calc";
        "super + o" =
          "wm go emoji";
        "super + ctrl + Return" =
          "rofi -show ssh";
        "super + {_,shift} + Return" =
          "{_,BASH_STARTUP=@${my.server.hostname} new_instance=1} wm go terminal";
        "super + {_,shift} + KP_Enter" =
          "{_,BASH_STARTUP=@${my.server.hostname} new_instance=1} wm go terminal";
        "super + {_,shift} + {w,x,c,f,e,v,m}" =
          "wm go {_,-n} {web,mail,chat,files,editor,video,music}";
        "super + ctrl + w" =
          "wm go wifi";
        "super + alt + w" =
          "firefox -P work";
      };
    };

    xdg.configFile."sxhkd/sxhkdrc".onChange = ''
      pkill ''${VERBOSE+-e} -USR1 -x sxhkd || true
    '';
  };

  programs.i3lock.enable = true;
  security.pam.services.i3lock.fprintAuth = false;

  nixpkgs.overlays = [
    (pkgs: prev: {
      bspwm = assert prev.bspwm.version == "0.9.10"; prev.bspwm.overrideAttrs (o: {
        src = pkgs.fetchFromGitHub {
          owner = "baskerville";
          repo = "bspwm";
          rev = "1560df35be303807052c235634eb8d59415c37ff";
          sha256 = "Ga3vLenEWM2pioRc/U4i4LW5wj97ekvKdJnyAOCjiHI=";
        };
        patches = o.patches or [] ++ optional config.broadcasting.enable
          (pkgs.fetchpatch {
            # hide_by_moving, useful for broadcasting windows
            url = "https://github.com/ncfavier/bspwm/commit/9e84eaa6eebe7faff7c7d0d2a911ed6a0d0b0296.patch";
            hash = "sha256-2SDGO3Q+/VXtagoqipBjaP0F4pQQl3qam/uKDchZO3I=";
          });
      });

      lemonbar-xft = prev.lemonbar-xft.overrideAttrs (o: {
        src = pkgs.fetchFromGitLab {
          owner = "protesilaos";
          repo = "lemonbar-xft";
          rev = "0042efd2ec1477ab96eb044ebba72a10aefff21f";
          sha256 = "sha256-SDQTvpqv4E5fbAbYDGfylk2w9bfXNSdNBdgKwXcfxFA=";
        };
        patches = o.patches or [] ++ [
          (builtins.toFile "lemonbar-xft-patch" ''
            Read whole lines of input.
            --- a/lemonbar.c
            +++ b/lemonbar.c
            @@ -1456 +1456,2 @@ main (int argc, char **argv)
            -    char input[4096] = {0, };
            +    char *input = NULL;
            +    size_t input_size = 0;
            @@ -1546,2 +1546,0 @@ main (int argc, char **argv)
            -    // Prevent fgets to block
            -    fcntl(STDIN_FILENO, F_SETFL, O_NONBLOCK);
            @@ -1562,3 +1561 @@ main (int argc, char **argv)
            -                input[0] = '\0';
            -                while (fgets(input, sizeof(input), stdin) != NULL)
            -                    ; // Drain the buffer, the last line is actually used
            +                getline(&input, &input_size, stdin);
          '')
        ];
      });
    })
  ];
}
