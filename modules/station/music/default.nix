{ config, pkgs, ... }: {
  hm = {
    services.mpd = {
      enable = true;
      musicDirectory = config.hm.xdg.userDirs.music;
      extraConfig = ''
        auto_update "yes"

        ${if config.sound.backend == "pulseaudio" then ''
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
      pkgs.shellScriptWith "music-rofi" ./music-rofi.sh {}
    }/bin/music-rofi" ];

    home.packages = with pkgs; [
      playerctl
      mpc_cli
      (shellScriptWith "music-play" ./music-play.sh {
        deps = [ mpc_cli ];
      })
      (shellScriptWith "music-notify" ./music-notify.sh {
        deps = [ mpc_cli playerctl dunst ];
      })
      (shellScriptWith "music-add" ./music-add.sh {
        deps = [ imagemagick ffmpeg-full audacity mpc_cli ];
      })
      songrec
    ];
  };
}
