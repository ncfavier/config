{ config, pkgs, ... }: {
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  hm = {
    home.packages = with pkgs; [
      (xfce.thunar.override {
        thunarPlugins = with xfce; [ thunar-volman thunar-archive-plugin ];
      })
      xfce.xfconf
      gnome.zenity
      gnome.file-roller
      (pkgs.linkFarm "glib-default-terminal" [ {
        # Stupid workaround for https://gitlab.gnome.org/GNOME/glib/-/issues/338
        name = "bin/tilix";
        path = "${pkgs.alacritty}/bin/alacritty";
      } ])
      (writeTextDir "share/thumbnailers/ffmpegthumbnailer.thumbnailer" ''
        [Thumbnailer Entry]
        MimeType=video/jpeg;video/mp4;video/mpeg;video/quicktime;video/x-ms-asf;video/x-ms-wm;video/x-ms-wmv;video/x-ms-asx;video/x-ms-wmx;video/x-ms-wvx;video/x-msvideo;video/x-flv;video/x-matroska;application/mxf;video/3gp;video/3gpp;video/dv;video/divx;video/fli;video/flv;video/mp2t;video/mp4v-es;video/msvideo;video/ogg;video/vivo;video/vnd.divx;video/vnd.mpegurl;video/vnd.rn-realvideo;application/vnd.rn-realmedia;video/vnd.vivo;video/webm;video/x-anim;video/x-avi;video/x-flc;video/x-fli;video/x-flic;video/x-m4v;video/x-mpeg;video/x-mpeg2;video/x-nsv;video/x-ogm+ogg;video/x-theora+ogg;audio/mpeg
        Exec=${pkgs.ffmpegthumbnailer}/bin/ffmpegthumbnailer -i %i -o %o -s %s -m
      '')
      (writeTextDir "share/thumbnailers/webp.thumbnailer" ''
        [Thumbnailer Entry]
        MimeType=image/webp
        Exec=${pkgs.imagemagick}/bin/convert -thumbnail %s %i %o
      '')
      (python3ScriptWithDeps "dbus-make-thumbnails" ./dbus-make-thumbnails.py (ps:
        with ps; [ pyxdg dbus-python pygobject3 ]))
    ];

    xdg.configFile = {
      "xfce4/xfconf/xfce-perchannel-xml/thunar.xml" = {
        source = config.lib.meta.mkMutableSymlink ./thunar.xml;
        force = true;
      };
      "Thunar/uca.xml".source = config.lib.meta.mkMutableSymlink ./uca.xml;
      "tumbler/tumbler.rc".source = ./tumbler.rc;
    };
  };
}
