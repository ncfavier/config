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
        (writeShellScriptBin "volume" ''
          if (( ! $# )); then
            pactl --format=json list sinks |
              jq -r --arg def "$(pactl get-default-sink)" '.[] | select(.name == $def) | "\(first(.volume[]) | .value_percent | rtrimstr("%")):\(.mute)"'
          else case $1 in
            mic)
              pactl --format=json list sources |
                jq -r --arg def "$(pactl get-default-source)" '.[] | select(.name == $def) | "\(first(.volume[]) | .value_percent | rtrimstr("%")):\(.mute)"'
              ;;
            mute) pactl set-sink-mute @DEFAULT_SINK@ 1;;
            unmute) pactl set-sink-mute @DEFAULT_SINK@ 0;;
            toggle) pactl set-sink-mute @DEFAULT_SINK@ toggle;;
            toggle-mic) pactl set-source-mute @DEFAULT_SOURCE@ toggle;;
            *) pactl set-sink-volume @DEFAULT_SINK@ "$1%";;
          esac fi
        '')
      ];
    }
  ];
}
