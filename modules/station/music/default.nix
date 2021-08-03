{ config, pkgs, ... }: {
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
    };

    programs.rofi.extraConfig.modi = "music:${
      pkgs.shellScriptWithDeps "music-rofi" ./music-rofi.sh []
    }/bin/music-rofi";

    home.packages = with pkgs; [
      mpc_cli
      (shellScriptWithDeps "music-play" ./music-play.sh [])
      (shellScriptWithDeps "music-notify" ./music-notify.sh [
        ffmpegthumbnailer xxd glib.bin
      ])
      (shellScriptWithDeps "music-add" ./music-add.sh [
        libxml2Python imagemagick ffmpeg-full youtube-dl audacity mpc_cli
      ])
      songrec
    ];
  };
}
