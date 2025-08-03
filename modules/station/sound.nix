{ lib, config, pkgs, ... }: with lib; {
  options.sound-backend = mkOption {
    type = types.enum [ "pulseaudio" "pipewire" ];
    default = "pipewire";
  };

  config = mkMerge [
    (mkIf (config.sound-backend == "pulseaudio") {
      hardware.pulseaudio = {
        enable = true;
        support32Bit = true;
      };
    })

    (mkIf (config.sound-backend == "pipewire") {
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;

        wireplumber.extraConfig.custom = {
          "wireplumber.settings" = {
            # https://github.com/marin-m/SongRec/issues/184
            "bluetooth.autoswitch-to-headset-profile" = false;
          };

          "monitor.bluez.rules" = [ {
            matches = [ { "node.name" = "~bluez_output.*"; } ];
            actions.update-props = {
              # https://wiki.archlinux.org/title/PipeWire#Noticeable_audio_delay_or_audible_pop/crack_when_starting_playback
              "session.suspend-timeout-seconds" = 0;
            };
          } ];
        };
      };

      security.rtkit.enable = true;

      environment.systemPackages = with pkgs; [
        easyeffects
      ];
    })

    {
      environment.systemPackages = with pkgs; [
        alsa-utils
        pulseaudio
        pavucontrol
        (shellScriptWith "mic-notify" {
          deps = [ jq pulseaudio ];
        } ''
          def=$(pactl get-default-source)
          IFS=: read -r volume mute < <(pactl --format=json list sources | jq -r --arg def "$def" '.[] | select(.name == $def) | "\(first(.volume[]) | .value_percent | rtrimstr("%")):\(.mute)"')
          if [[ $mute == true ]]; then
            icon=microphone-disabled-symbolic
          else
            icon=audio-input-microphone-symbolic
          fi
          id=0x1F399 # 🎙️
          dunstify -i "$icon" -r "$id" "Microphone: $volume%"
        '')
        (shellScriptWith "volume" {
          deps = [ jq pulseaudio ];
          completion = ''
            complete -W 'mic deafen undeafen toggle-deaf mute unmute toggle-mute' volume
          '';
        } ''
          print-volume() {
            jq -r --arg def "$1" '.[] | select(.name == $def) | (first(.volume[]) | .value_percent | rtrimstr("%")) + if .mute then " (muted)" else "" end'
          }
          if (( ! $# )); then
            pactl --format=json list sinks | print-volume "$(pactl get-default-sink)"
          else case $1 in
            mic)
              shift
              if (( ! $# )); then
                pactl --format=json list sources | print-volume "$(pactl get-default-source)"
              else
                pactl set-source-volume @DEFAULT_SOURCE@ "$1%"
              fi
              ;;
            deafen) pactl set-sink-mute @DEFAULT_SINK@ 1;;
            undeafen) pactl set-sink-mute @DEFAULT_SINK@ 0;;
            toggle-deaf) pactl set-sink-mute @DEFAULT_SINK@ toggle;;
            mute) pactl set-source-mute @DEFAULT_SOURCE@ 1;;
            unmute) pactl set-source-mute @DEFAULT_SOURCE@ 0;;
            toggle-mute) pactl set-source-mute @DEFAULT_SOURCE@ toggle;;
            *) pactl set-sink-volume @DEFAULT_SINK@ "$1%";;
          esac fi
        '')
      ];
    }
  ];
}
