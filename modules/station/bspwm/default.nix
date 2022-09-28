{ lib, config, pkgs, ... }: with lib; let
  bar = with pkgs; shellScriptWith "bar" ./bar.sh {
    deps = [
      config-cli lemonbar-xft xtitle xkb-switch
    ];
  };
in {
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
      rules = rec {
        firefox = {
          desktop = "web";
          follow = true;
        };
        thunderbird = {
          desktop = "mail";
          follow = true;
        };
        "Alacritty:irc" = {
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
        "mpv"
        "File-roller"
        "Lxappearance"
        "Pavucontrol"
        "Alacritty:calendar"
        "Qemu-system-x86_64"
        "Gucharmap"
        "Xfd"
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

    home.packages = with pkgs; [
      xdo
      i3lock
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
          compreply -W '-n terminal chat irc editor web browser mail files music video volume calendar wifi'
        fi
      }
      complete -F _wm wm
    '';

    services.sxhkd = {
      enable = true;
      extraOptions = [ "-m 1" ];
      keybindings = {
        "super + @r" =
          "${config.hm.xdg.configHome}/bspwm/bspwmrc";
        "super + {_,shift} + {_,ctrl} + {ampersand,eacute,quotedbl,apostrophe,parenleft,minus,egrave,underscore,ccedilla}" =
          "wm {focus-workspace,move-window-to-workspace} {_,^}{1-9}";
        "super + {_,shift} + {button4,button5,Left,Right}" =
          "wm {focus-workspace,move-window-to-workspace} {prev,next,prev,next}";
        "super + {_,shift} + {a,z}" =
          "wm {focus-workspace,move-window-to-workspace} {any.urgent,last}";
        "super + ctrl + {_,shift} + z" =
          "wm {focus-workspace,move-window-to-workspace} last.occupied";
        "super + {plus,equal}" =
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
        "super + alt + {space,Left,Right,Down,Up,r,z,y,c,b,f,u}" =
          "mpc -q {toggle,prev,next,volume -2,volume +2,repeat,random,single,stop,seek -3,seek +3,update}";
        "XF86Audio{Play,Prev,Next,Stop}" =
          "mpc -q {toggle,prev,next,stop}";
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
        "super + {_,shift,ctrl} + space" =
          "rofi -sidebar-mode -show-icons -modi drun,run,window -show {drun,run,window}";
        "super + asterisk" =
          "rofi -show calc";
        "super + o" =
          ''rofi -show emoji -theme-str 'configuration \{ font: "sans 14"; \}' '';
        "super + ctrl + f" =
          "rofi -show file-browser";
        "super + ctrl + Return" =
          "rofi -show ssh";
        "super + {_,shift} + Return" =
          "{_,BASH_STARTUP=@${my.server.hostname}} wm go terminal";
        "super + {_,shift} + {w,x,c,f,e,v,m}" =
          "wm go {_,-n} {web,mail,chat,files,editor,video,music}";
        "super + ctrl + w" =
          "wm go wifi";
      };
    };

    xdg.configFile."sxhkd/sxhkdrc".onChange = ''
      pkill ''${VERBOSE+-e} -USR1 -x sxhkd || true
    '';
  };

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
