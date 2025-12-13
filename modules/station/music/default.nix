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
    services.playerctld = {
      enable = true;
      package = pkgs.playerctl.overrideAttrs (drv: {
        patches = drv.patches or [] ++ [
          (pkgs.fetchpatch {
            # fix: Checks if message body is NULL before getting number of children.
            url = "https://patch-diff.githubusercontent.com/raw/altdesktop/playerctl/pull/349.patch";
            hash = "sha256-DtxWv8VKugpOxaGIM/CnD0Dqoo86Q9rmX4ALwwqIkXU=";
          })
        ];
      });
    };

    programs.ncmpcpp = {
      enable = true;
      settings.lyrics_directory = "${config.hm.xdg.dataHome}/lyrics"; # don't pollute ~
    };

    programs.rofi.extraConfig.modes = [ "music:${
      pkgs.shellScriptWith "music-rofi" {} (readFile ./music-rofi.sh)
    }/bin/music-rofi" ];

    dconf.settings = {
      "de/wagnermartin/Plattenalbum" = {
        manual-connection = true;
        host = "localhost";
        mpris = false;
      };
    };

    home.packages = with pkgs; [
      mpc
      plattenalbum
      quodlibet
      (shellScriptWith "music-play" {
        deps = [ mpc ];
      } (readFile ./music-play.sh))
      (shellScriptWith "music-notify" {
        deps = [ mpc playerctl dunst ];
      } (readFile ./music-notify.sh))
      (shellScriptWith "music-add" {
        deps = [ curl htmlq jq yt-dlp imagemagick ffmpeg-full audacity mpc ];
      } (readFile ./music-add.sh))
      songrec
    ];
  };
}
