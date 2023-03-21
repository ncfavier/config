{ config, pkgs, ... }: {
  nixpkgs.overlays = [ (self: super: {
    mpd = super.mpd.overrideAttrs (o: { # FIXME
      patches = o.patches or [] ++ [ (pkgs.fetchpatch {
        url = "https://github.com/MusicPlayerDaemon/MPD/commit/9bcba41cd66a33df9e0267f352640ed3925c292e.patch";
        hash = "sha256-riw+BAkoOk2NyLcRZUNXiEdYAnU73KGlFDwKffo68ns=";
      }) ];
    });
  }) ];

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
