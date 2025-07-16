{ lib, config, pkgs, ... }: with lib; let
  fonts = with config.theme; [
    "${font}:size=${toString fontSize};${toString (config.lib.x.dpiScale 2)}"
    "${font}:size=${toString fontSize}:weight=bold;${toString (config.lib.x.dpiScale 2)}"
    "emoji:scale=6;${toString (config.lib.x.dpiScale 2)}"
    "Material Design Icons;${toString (config.lib.x.dpiScale 3)}"
  ];
  boldFont = 2;
  iconFont = length fonts;
  bold = t: "%{T${toString boldFont}}${t}%{T-}";
  icon = t: "%{T${toString iconFont}}${t}%{T-}";

  # Runs ${action} every time some event happens (and at least on the specified interval),
  # without queuing more than one event.
  # Assumes ${event} produces a line of output every time the event happens.
  makeEventScript =
    name: { interval ? null }: event: action:
    pkgs.writeShellScriptBin name ''
      shopt -s lastpipe
      ${event} |
      while
        ${action}
        ${if interval == null then "read -r" else "read -r -t ${toString interval} || (( $? > 128 ))"}
      do
        while read -t 0; do
          read -r || break
        done
      done
    '';
in {
  options.battery = {
    battery = mkOption {
      type = types.str;
      default = "BAT0";
    };
    adapter = mkOption {
      type = types.str;
      default = "ADP1";
    };
    fullAt = mkOption {
      type = types.int;
      default = 100;
    };
  };

  config = {
    cachix.derivationsToPush = [ config.hm.services.polybar.package ];

    hm = {
      services.polybar = {
        enable = true;
        package = pkgs.polybarFull.overrideAttrs (drv: {
          patches = drv.patches or [] ++ [
            (pkgs.fetchpatch {
              url = "https://github.com/polybar/polybar/commit/2d003840465fe02ecba2209e9dc922d3263542b8.patch";
              excludes = [ "CHANGELOG.md" ];
              hash = "sha256-u0FJ5zxluZWJCOYM6ZYvEpTgDMFLWJwHjhY0pyMupgo=";
            })
          ];
        });
        script = ''
          . /etc/set-environment
          polybar main &
        '';

        settings = with config.theme; {
          "bar/main" = {
            inherit background foreground;
            inherit (config.services.xserver) dpi;
            width = "100%";
            height = "${toString (config.lib.x.dpiScale barHeight)}px";
            border-bottom-size = borderWidth;
            border-color = borderColor;
            line-size = "2pt";
            radius = 0;
            modules.left = "wm title";
            modules.right = "memory keyboard systemd dunst music sound light battery date vpn tray";
            module.margin = "5pt";
            font = fonts;
            enable-ipc = true;
            enable-struts = true;
            wm-restack = "bspwm";
          };

          "module/wm" = let
            padding = "7pt";
            default = {
              text = "%{A2:wm move-window-to-workspace %name% :}%{A3:wm launch %name% :}%{O${padding}}${icon "%icon%"}%{O${padding}}%{A}%{A}";
              padding = 0;
            };
          in {
            type = "internal/bspwm";
            ws-icon.text = [ "web;󰇧" "mail;󰇮" "chat;󰭹" "files;󰉋" ];
            ws-icon.default = "󰋙";
            pin-workspaces = false;
            format.text = "<label-state>";
            label.occupied = default;
            label.empty = default // {
              foreground = foregroundAlt;
            };
            label.urgent = default // {
              foreground = hot;
            };
            label.focused = default // {
              underline = foreground;
              empty = default // {
                foreground = foregroundAlt;
                underline = foregroundAlt;
              };
              urgent = default // {
                foreground = hot;
                underline = hot;
              };
            };
          };

          "module/title" = {
            type = "internal/xwindow";
            label.text = "%{A1:bspc node -t ~floating:}%{A2:bspc node -c:}%{A3:bspc desktop -l next:}%title:0:65:...%%{A}%{A}%{A}";
          };

          "module/memory" = {
            type = "internal/memory";
            warn-percentage = 90;
            format.text = "";
            format.warn.text = "${icon "󰍛"} <label-warn>";
            format.warn.foreground = hot;
          };

          "module/keyboard" = {
            type = "internal/xkeyboard";
            format.text = "<label-layout>";
            label.layout.text = "%icon%";
            layout.icon.text = map
              (layout: "${layout};${icon "󰌌"} ${layout}")
              (tail (splitString "," config.services.xserver.xkb.layout));
            layout.icon.default = "";
          };

          "module/systemd" = {
            type = "custom/script";
            tail = true;
            exec = getExe pkgs.myPolybarScripts.systemd;
          };

          "module/dunst" = {
            type = "custom/script";
            tail = true;
            exec = getExe pkgs.myPolybarScripts.dunst;
          };

          "module/music" = let
            actions = t: "%{A1:wm launch music:}%{A2:#music.stop:}%{A4:mpc -q volume +2:}%{A5:mpc -q volume -2:}${t}%{A}%{A}%{A}%{A}";
          in {
            type = "internal/mpd";
            format.playing.text = actions "${icon "󰏤"} %{A3:#music.pause:}<label-song>%{A}";
            format.paused.text = actions "${icon "󰐊"} %{A3:#music.play:}<label-song>%{A}";
            label.song.text = "%{A1:music-notify:}${bold "%artist:0:25:...%"} – %title:0:25:...%%{A}";
          };

          "module/vpn" = {
            type = "custom/script";
            tail = true;
            exec = getExe pkgs.myPolybarScripts.vpn;
          };

          "module/sound" = {
            type = "internal/pulseaudio";
            interval = 2;
            label.volume.text = "%{A3:wm launch volume:}${icon "󰕾"} %percentage%%%{A}";
            label.muted.text = "%{A3:wm launch volume:}${icon "󰝟"}%{A}";
            label.muted.foreground = foregroundAlt;
          };

          "module/light" = {
            type = "internal/backlight";
            enable-scroll = true;
            scroll-interval = 2;
            format.text = "<ramp> <label>";
            label.text = "%percentage%%";
            ramp.text = [ "󰃜" "󰃛" "󰃚" ];
            ramp.font = iconFont;
          };

          "module/battery" = {
            type = "internal/battery";
            inherit (config.battery) battery adapter;
            full-at = config.battery.fullAt;
            low-at = 15;
            poll-interval = 1;
            ramp.capacity.text = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
            ramp.capacity.font = iconFont;
            ramp.charging.text = [ "󰢟" "󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅" ];
            ramp.charging.font = iconFont;
            format.full.text = "${icon "󱈑"} <label-full>";
            format.charging.text = "<ramp-charging> <label-charging>";
            format.discharging.text = "<ramp-capacity> <label-discharging>";
            format.low.text = "${icon "󱃍"} <label-low>";
            format.low.foreground = hot;
          };

          "module/date" = {
            type = "internal/date";
            interval = 1;
            format.text = "${icon "󰅐"} <label>";
            label.text = "%{A3:wm launch calendar:}%date%%{A}";
            date.text = "%a %d ${bold "%H:%M"}";
            date.alt = "%Y-%m-%d ${bold "%H:%M:%S"}";
          };

          "module/tray" = {
            type = "internal/tray";
            tray.spacing = "2pt";
            tray.size = "80%";
          };
        };
      };

      systemd.user.services.polybar = {
        # Polybar needs to start after bspwm, see https://github.com/nix-community/home-manager/issues/213
        Install.WantedBy = mkForce [ "graphical-session-bspwm.target" ];
        Unit.After = [ "graphical-session-bspwm.target" ];

        Service.ExecStopPost = "${config.hm.xsession.windowManager.bspwm.package}/bin/bspc config top_padding 0";
      };

      home.packages = attrValues pkgs.myPolybarScripts;
    };

    fonts.packages = with pkgs; [ material-design-icons ];

    nixpkgs.overlays = [ (self: super: {
      myPolybarScripts = with self; with config.theme; {
        dunst = makeEventScript "polybar-dunst" {}
          "dbus-monitor --profile path=/org/freedesktop/Notifications,interface=org.freedesktop.DBus.Properties,member=PropertiesChanged"
          ''
            if [[ $(timeout 0.1s dunstctl is-paused) == true ]]; then
              printf '%s\n' "${icon "󰂛"}"
            else
              printf '\n'
            fi
          '';
        vpn = makeEventScript "polybar-vpn" {}
          "ip -o monitor route"
          ''
            output=()
            nmcli connection show --active | tail -n +2 |
            while read -r _ _ type dev; do
              if [[ $type == wireguard ]]; then
                item='%{A1:wg-toggle:}${icon "󰯄"}%{A}'
                if ! ip -j route show default table all | jq -e --arg dev "$dev" 'any(.[].dev; . == $dev)' > /dev/null; then
                  item="%{F${foregroundAlt}}$item%{F-}"
                fi
                output+=("$item")
              elif [[ $type == vpn ]]; then
                output+=("${icon "󰌆"}")
              fi
            done
            printf '%s\n' "''${output[*]}"
          '';
        systemd = makeEventScript "polybar-systemd" { interval = 60; }
          "journalctl --follow --lines=0 --identifier=systemd"
          ''
            failed_system_units=() failed_user_units=()
            systemctl list-units --failed --plain --no-legend |
            while read -r unit _; do
              failed_system_units+=("$unit")
            done
            systemctl --user list-units --failed --plain --no-legend |
            while read -r unit _; do
              failed_user_units+=("$unit")
            done
            output=
            if (( ''${#failed_system_units[@]} || ''${#failed_user_units[@]} )); then
              output="${icon "󰀩"}"
              for unit in "''${failed_system_units[@]}"; do
                output+=" %{A1:sudo systemctl restart $unit:}''${unit%.service}%{A}"
              done
              for unit in "''${failed_user_units[@]}"; do
                output+=" %{A1:systemctl --user restart $unit:}''${unit%.service}%{A}"
              done
              output="%{F${hot}}$output%{F-}"
            fi
            printf '%s\n' "$output"
          '';
      };
    }) ];
  };
}
