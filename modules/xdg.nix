{ lib, this, config, pkgs, ... }: with lib; {
  config = mkMerge [
    {
      hm.xdg.enable = true;
    }

    (mkIf this.isStation {
      hm = {
        home.packages = with pkgs; [
          xdg-user-dirs
          (writeShellScriptBin "xdg-terminal-exec" ''
            wm go terminal "$@"
          '')
        ];

        home.file = genAttrs [ "music" "pictures" "my" ] (dir: {
          source = config.hm.lib.file.mkOutOfStoreSymlink config.synced.${dir}.path;
        });

        xdg = {
          userDirs = {
            enable = true;
            createDirectories = true;

            desktop     = config.my.home;
            download    = config.my.home;
            documents   = config.my.home;
            templates   = config.my.home;
            publicShare = config.my.home;
            music       = "${config.my.home}/music";
            pictures    = "${config.my.home}/pictures";
            videos      = "${config.my.home}/videos";
          };

          mimeApps = with config.lib.mimeTypes; {
            enable = true;
            associations.added = mkMerge (mapAttrsToList (n: ms: genAttrs ms (_: [ "${n}.desktop" ])) {
              firefox = dirs ++ text ++ images ++ media;
            });
            defaultApplications = mkMerge (mapAttrsToList (n: ms: genAttrs ms (_: [ "${n}.desktop" ])) {
              thunar = dirs;
              nvim = text;
              firefox = [
                "application/pdf"
                "application/x-extension-htm"
                "application/x-extension-html"
                "application/x-extension-shtml"
                "application/x-extension-xht"
                "application/x-extension-xhtml"
                "application/xhtml+xml"
                "image/svg+xml"
                "text/html"
                "text/xml"
                "x-scheme-handler/chrome"
                "x-scheme-handler/ftp"
                "x-scheme-handler/http"
                "x-scheme-handler/https"
                "x-scheme-handler/unknown"
              ];
              thunderbird = [
                "message/rfc822"
                "x-scheme-handler/feed"
                "x-scheme-handler/mailto"
                "x-scheme-handler/news"
                "x-scheme-handler/rss+xml"
                "x-scheme-handler/x-extension-rss"
              ];
              imv-dir = images;
              mpv = media;
              "org.gnome.Fileroller" = archives;
              transmission-gtk = [
                "application/x-bittorrent"
                "x-scheme-handler/magnet"
              ];
              amfora = [
                "x-scheme-handler/gemini"
              ];
            });
          };

          configFile."mimeapps.list".force = true;
        };
      };

      lib.mimeTypes = {
        dirs = [
          "inode/directory"
        ];
        text = [
          "application/x-shellscript"
          "text/english"
          "text/plain"
          "text/x-c"
          "text/x-c++"
          "text/x-c++hdr"
          "text/x-c++src"
          "text/x-chdr"
          "text/x-csrc"
          "text/x-java"
          "text/x-makefile"
          "text/x-moc"
          "text/x-pascal"
          "text/x-tcl"
          "text/x-tex"
        ];
        images = [
          "image/avif"
          "image/avif-sequence"
          "image/bmp"
          "image/gif"
          "image/jpeg"
          "image/jpg"
          "image/pjpeg"
          "image/png"
          "image/tiff"
          "image/webp"
          "image/x-bmp"
          "image/x-pcx"
          "image/x-png"
          "image/x-portable-anymap"
          "image/x-portable-bitmap"
          "image/x-portable-graymap"
          "image/x-portable-pixmap"
          "image/x-tga"
          "image/x-xbitmap"
        ];
        media = [
          "application/mxf"
          "application/ogg"
          "application/sdp"
          "application/smil"
          "application/streamingmedia"
          "application/vnd.apple.mpegurl"
          "application/vnd.ms-asf"
          "application/vnd.rn-realmedia"
          "application/vnd.rn-realmedia-vbr"
          "application/x-cue"
          "application/x-extension-m4a"
          "application/x-extension-mp4"
          "application/x-matroska"
          "application/x-mpegurl"
          "application/x-ogg"
          "application/x-ogm"
          "application/x-ogm-audio"
          "application/x-ogm-video"
          "application/x-shorten"
          "application/x-smil"
          "application/x-streamingmedia"
          "audio/3gpp"
          "audio/3gpp2"
          "audio/AMR"
          "audio/aac"
          "audio/ac3"
          "audio/aiff"
          "audio/amr-wb"
          "audio/dv"
          "audio/eac3"
          "audio/flac"
          "audio/m3u"
          "audio/m4a"
          "audio/mp1"
          "audio/mp2"
          "audio/mp3"
          "audio/mp4"
          "audio/mpeg"
          "audio/mpeg2"
          "audio/mpeg3"
          "audio/mpegurl"
          "audio/mpg"
          "audio/musepack"
          "audio/ogg"
          "audio/opus"
          "audio/rn-mpeg"
          "audio/scpls"
          "audio/vnd.dolby.heaac.1"
          "audio/vnd.dolby.heaac.2"
          "audio/vnd.dts"
          "audio/vnd.dts.hd"
          "audio/vnd.rn-realaudio"
          "audio/vorbis"
          "audio/wav"
          "audio/webm"
          "audio/x-aac"
          "audio/x-adpcm"
          "audio/x-aiff"
          "audio/x-ape"
          "audio/x-m4a"
          "audio/x-matroska"
          "audio/x-mp1"
          "audio/x-mp2"
          "audio/x-mp3"
          "audio/x-mpegurl"
          "audio/x-mpg"
          "audio/x-ms-asf"
          "audio/x-ms-wma"
          "audio/x-musepack"
          "audio/x-pls"
          "audio/x-pn-au"
          "audio/x-pn-realaudio"
          "audio/x-pn-wav"
          "audio/x-pn-windows-pcm"
          "audio/x-realaudio"
          "audio/x-scpls"
          "audio/x-shorten"
          "audio/x-tta"
          "audio/x-vorbis"
          "audio/x-vorbis+ogg"
          "audio/x-wav"
          "audio/x-wavpack"
          "video/3gp"
          "video/3gpp"
          "video/3gpp2"
          "video/avi"
          "video/divx"
          "video/dv"
          "video/fli"
          "video/flv"
          "video/mkv"
          "video/mp2t"
          "video/mp4"
          "video/mp4v-es"
          "video/mpeg"
          "video/msvideo"
          "video/ogg"
          "video/quicktime"
          "video/vnd.divx"
          "video/vnd.mpegurl"
          "video/vnd.rn-realvideo"
          "video/webm"
          "video/x-avi"
          "video/x-flc"
          "video/x-flic"
          "video/x-flv"
          "video/x-m4v"
          "video/x-matroska"
          "video/x-mpeg2"
          "video/x-mpeg3"
          "video/x-ms-afs"
          "video/x-ms-asf"
          "video/x-ms-wmv"
          "video/x-ms-wmx"
          "video/x-ms-wvxvideo"
          "video/x-msvideo"
          "video/x-ogm"
          "video/x-ogm+ogg"
          "video/x-theora"
          "video/x-theora+ogg"
        ];
        archives = [
          "application/bzip2"
          "application/gzip"
          "application/vnd.android.package-archive"
          "application/vnd.debian.binary-package"
          "application/vnd.ms-cab-compressed"
          "application/x-7z-compressed"
          "application/x-7z-compressed-tar"
          "application/x-ace"
          "application/x-alz"
          "application/x-ar"
          "application/x-archive"
          "application/x-arj"
          "application/x-brotli"
          "application/x-bzip"
          "application/x-bzip-brotli-tar"
          "application/x-bzip-compressed-tar"
          "application/x-bzip1"
          "application/x-bzip1-compressed-tar"
          "application/x-cabinet"
          "application/x-cd-image"
          "application/x-chrome-extension"
          "application/x-compress"
          "application/x-compressed-tar"
          "application/x-cpio"
          "application/x-deb"
          "application/x-ear"
          "application/x-gtar"
          "application/x-gzip"
          "application/x-gzpostscript"
          "application/x-java-archive"
          "application/x-lha"
          "application/x-lhz"
          "application/x-lrzip"
          "application/x-lrzip-compressed-tar"
          "application/x-lz4"
          "application/x-lz4-compressed-tar"
          "application/x-lzip"
          "application/x-lzip-compressed-tar"
          "application/x-lzma"
          "application/x-lzma-compressed-tar"
          "application/x-lzop"
          "application/x-ms-dos-executable"
          "application/x-ms-wim"
          "application/x-rar"
          "application/x-rar-compressed"
          "application/x-rpm"
          "application/x-rzip"
          "application/x-rzip-compressed-tar"
          "application/x-source-rpm"
          "application/x-stuffit"
          "application/x-tar"
          "application/x-tarz"
          "application/x-tzo"
          "application/x-war"
          "application/x-xar"
          "application/x-xz"
          "application/x-xz-compressed-tar"
          "application/x-zip"
          "application/x-zip-compressed"
          "application/x-zoo"
          "application/x-zstd-compressed-tar"
          "application/zip"
          "application/zstd"
        ];
      };
    })
  ];
}
