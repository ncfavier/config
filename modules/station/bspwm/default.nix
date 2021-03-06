{ lib, config, theme, pkgs, ... }: with lib; let
  bar = with pkgs; shellScriptWithDeps "bar" ./bar.sh [
    config-cli lemonbar-xft xdo xtitle xkb-switch
  ];
in {
  hm = {
    xsession.windowManager.bspwm = {
      enable = true;
      monitors.focused = [ "1" "2" "3" "4" "5" "6" "web" "mail" "chat" "files" ];
      settings = with theme; {
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
        "Firefox" = {
          desktop = "web";
          follow = true;
        };
        "Thunderbird" = {
          desktop = "mail";
          follow = true;
        };
        "Alacritty:irc" = {
          desktop = "chat";
          follow = true;
        };
        "Thunar" = {
          desktop = "files";
          follow = true;
        };
        ".thunar-wrapped_" = { # ugh
          desktop = "files";
          follow = true;
        };
      } // genAttrs [
        "feh"
        "mpv"
        ".file-roller-wrapped_" # ugh
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
        "ibus-daemon --daemonize --replace --xim"
      ];
    };

    home.packages = with pkgs; [
      (shellScriptWithDeps "wm" ./wm.sh [ xtitle ])
      bar
    ];

    services.sxhkd = {
      enable = true;
      extraOptions = [ "-m 1" ];
      keybindings = {
        "super + r" =
          "${config.hm.xdg.configHome}/bspwm/bspwmrc";
        "super + {_,shift} + {ampersand,eacute,quotedbl,apostrophe,parenleft,minus,egrave,underscore,ccedilla}" =
          "wm {focus-workspace,move-window-to-workspace} ^{1-9}";
        "super + {_,shift} + {button4,button5,Left,Right}" =
          "wm {focus-workspace,move-window-to-workspace} {prev,next,prev,next}";
        "super + {_,shift} + {a,n,z}" =
          "wm {focus-workspace,move-window-to-workspace} {any.urgent,any.!occupied,last}";
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
          '' bspc node -l "$(bspc query -T -n | jq -r 'if .client.layer == "above" then "normal" else "below" end')" '';
        "super + greater" =
          '' bspc node -l "$(bspc query -T -n | jq -r 'if .client.layer == "below" then "normal" else "above" end')" '';
        "super + {_,shift} + q" =
          "bspc node -{c,k}";

        "super + shift + l" =
          "${pkgs.i3lock}/bin/i3lock -c 000000";
        "{super + Escape,XF86PowerOff}" =
          "power";
        "super + {_,alt} + question" =
          "{nixos,home-manager}-help";
        "super + {_,shift} + d" =
          "dunstctl {close,close-all}";
        "super + grave" =
          "dunstctl history-pop";
        "super + alt + {space,Left,Right,Down,Up,r,z,y,c,b,f,u}" =
          "mpc -q {toggle,prev,next,volume -2,volume +2,repeat,random,single,clear,seek -3,seek +3,update}";
        "XF86Audio{Play,Prev,Next,Stop}" =
          "mpc -q {toggle,prev,next,stop}";
        "XF86Audio{Lower,Raise}Volume" =
          "volume {-,+}2";
        "XF86AudioMute" =
          "volume toggle";
        "{_,super} + {_,ctrl} + {_,alt} + {_,shift} + Print" =
          "shoot {_,-c} {_,-n} {_,-v} {_,-u}";
        "super + {_,shift,ctrl} + space" =
          "rofi -sidebar-mode -show-icons -modi drun,run,window -show {drun,run,window}";
        "super + shift + s" =
          "rofi -show ssh";
        "super + asterisk" =
          "rofi -show calc";
        "super + o" =
          "rofi -show emoji";
        "super + ctrl + f" =
          "rofi -show file-browser";
        "super + {_,shift} + {Return,f,w,c,e,v}" =
          "wm go {_,-n} {terminal,files,web,chat,editor,video}";
        "super + {_,shift} + m" =
          "wm go {music,mail}";
        "super + ctrl + w" =
          "wm go wifi";
      };
    };

    xdg.configFile."sxhkd/sxhkdrc".onChange = ''
      ${pkgs.procps}/bin/pkill -USR1 -x sxhkd || true
    '';
  };

  nixpkgs.overlays = [
    (self: super: {
      lemonbar-xft = super.lemonbar-xft.overrideAttrs (o: {
        src = self.fetchFromGitLab {
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
