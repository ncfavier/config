{ syncedFolders, pkgs, ... }: {
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
        ffmpegthumbnailer xxd glib.bin
      ])
      (shellScriptWithDeps "music-add" ./music-add.sh [
        libxml2Python imagemagick ffmpeg-full youtube-dl audacity mpc_cli
      ])
      (songrec.overrideAttrs (o: { # TODO https://nixpk.gs/pr-tracker.html?pr=126891
        postInstall = ''
          mv packaging/rootfs/usr/share "$out"/share
        '';
      }))
    ];
  };
}
