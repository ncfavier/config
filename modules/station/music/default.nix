{ lib, config, pkgs, ... }: with lib; {
  hm = {
    services.mpd = {
      enable = true;
      musicDirectory = config.hm.xdg.userDirs.music;
      extraConfig = ''
        auto_update "yes"

        ${if config.sound-backend == "pulseaudio" then ''
        audio_output {
          type "pulse"
          name "PulseAudio"
        }
        '' else ''
        audio_output {
          type "pipewire"
          name "PipeWire"
        }
        ''}
      '';
    };

    services.mpd-mpris.enable = true;
    services.playerctld.enable = true;

    programs.ncmpcpp = {
      enable = true;
      settings.lyrics_directory = "${config.hm.xdg.dataHome}/lyrics"; # don't pollute ~
    };

    programs.rofi.extraConfig.modes = [ "music:${
      pkgs.shellScriptWith "music-rofi" {} (readFile ./music-rofi.sh)
    }/bin/music-rofi" ];

    home.packages = with pkgs; [
      playerctl
      mpc_cli
      (shellScriptWith "music-play" {
        deps = [ mpc_cli ];
      } (readFile ./music-play.sh))
      (shellScriptWith "music-notify" {
        deps = [ mpc_cli playerctl dunst ];
      } (readFile ./music-notify.sh))
      (shellScriptWith "music-add" {
        deps = [ imagemagick ffmpeg-full audacity mpc_cli ];
      } (readFile ./music-add.sh))
      songrec
    ];
  };
}
