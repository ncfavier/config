{ config, pkgs, ... }: {
  hm = {
    services.mpd = {
      enable = true;
      musicDirectory = config.hm.xdg.userDirs.music;
      extraConfig = ''
        auto_update "yes"

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

    programs.rofi.extraConfig.modes = [ "music:${
      pkgs.shellScriptWith "music-rofi" ./music-rofi.sh {}
    }/bin/music-rofi" ];

    home.packages = with pkgs; [
      mpc_cli
      (shellScriptWith "music-play" ./music-play.sh {})
      (shellScriptWith "music-notify" ./music-notify.sh {
        deps = [
          ffmpegthumbnailer xxd glib.bin
        ];
      })
      (shellScriptWith "music-add" ./music-add.sh {
        deps = [
          htmlq imagemagick ffmpeg-full audacity mpc_cli
        ];
      })
      songrec
    ];
  };
}
