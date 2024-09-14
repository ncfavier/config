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
