{ config, utils, pkgs, ... }: {
  hm = {
    services.mpd = {
      enable = true;
      musicDirectory = config.synced.music.path;
      extraConfig = ''
        audio_output {
          type "pulse"
          name "PulseAudio"
        }
      '';
    };

    programs.ncmpcpp = {
      enable = true;
      settings.lyrics_directory = "${config.hm.xdg.dataHome}/lyrics";
    };

    programs.rofi.extraConfig.modi = "music:${
      utils.shellScriptWith "music-rofi" ./music-rofi.sh {}
    }/bin/music-rofi";

    home.packages = with pkgs; [
      mpc_cli
      (utils.shellScriptWith "music-play" ./music-play.sh {})
      (utils.shellScriptWith "music-notify" ./music-notify.sh {
        deps = [
          ffmpegthumbnailer xxd glib.bin
        ];
      })
      (utils.shellScriptWith "music-add" ./music-add.sh {
        deps = [
          htmlq imagemagick ffmpeg-full audacity mpc_cli
        ];
      })
      songrec
    ];
  };
}
