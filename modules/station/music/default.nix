{ pkgs, syncedFolders, ... }: {
  hm = {
    services.mpd = {
      enable = true;
      musicDirectory = syncedFolders.music.path;
      extraConfig = ''
        audio_output {
          type "pulse"
          name "PulseAudio"
        }
      '';
    };

    programs.ncmpcpp = {
      enable = true;
    };

    home.packages = with pkgs; [
      mpc_cli
      (shellScriptWithDeps "music" ./music.sh [])
      (shellScriptWithDeps "music-notify" ./music-notify.sh [
        ffmpegthumbnailer
      ])
      (shellScriptWithDeps "music-add" ./music-add.sh [
        libxml2Python imagemagick ffmpeg-full youtube-dl audacity mpc_cli
      ])
    ];
  };
}
