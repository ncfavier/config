{ lib, config, utils, pkgs, ... }: with lib; {
  programs.dconf.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # https://github.com/NixOS/nixpkgs/pull/126832
  environment.sessionVariables.GIO_EXTRA_MODULES = "${config.services.gvfs.package}/lib/gio/modules";
  environment.variables.GIO_EXTRA_MODULES = mkForce config.environment.sessionVariables.GIO_EXTRA_MODULES;

  hm = {
    home.packages = with pkgs; let
      thumbnailerScript = script: "${writeShellScript "thumbnailer-script" ''
        i=$1 u=$2 o=$3 s=$4
        if [[ ! $i && $u ]]; then
          [[ $u == trash://* ]] &&
              u=file://''${XDG_DATA_HOME:-~/.local/share}/Trash/files''${u#trash://}
          u=''${u#file://}
          printf -v i %b "''${u//%/'\x'}"
        fi
        ${script}
      ''} %i %u %o %s";
    in [
      (xfce.thunar.override {
        thunarPlugins = with xfce; [
          thunar-volman
          thunar-archive-plugin
          thunar-media-tags-plugin
        ];
      })
      xfce.xfconf
      gnome.zenity
      gnome.file-roller
      (linkFarm "glib-default-terminal" [ {
        # Stupid workaround for https://gitlab.gnome.org/GNOME/glib/-/issues/338
        name = "bin/tilix";
        path = "${alacritty}/bin/alacritty";
      } ])
      (writeTextDir "share/thumbnailers/ffmpegthumbnailer.thumbnailer" ''
        [Thumbnailer Entry]
        MimeType=video/jpeg;video/mp4;video/mpeg;video/quicktime;video/x-ms-asf;video/x-ms-wm;video/x-ms-wmv;video/x-ms-asx;video/x-ms-wmx;video/x-ms-wvx;video/x-msvideo;video/x-flv;video/x-matroska;application/mxf;video/3gp;video/3gpp;video/dv;video/divx;video/fli;video/flv;video/mp2t;video/mp4v-es;video/msvideo;video/ogg;video/vivo;video/vnd.divx;video/vnd.mpegurl;video/vnd.rn-realvideo;application/vnd.rn-realmedia;video/vnd.vivo;video/webm;video/x-anim;video/x-avi;video/x-flc;video/x-fli;video/x-flic;video/x-m4v;video/x-mpeg;video/x-mpeg2;video/x-nsv;video/x-ogm+ogg;video/x-theora+ogg;audio/mpeg
        Exec=${thumbnailerScript '' exec ${ffmpegthumbnailer}/bin/ffmpegthumbnailer -i "$i" -o "$o" -s "$s" -m ''}
      '')
      (writeTextDir "share/thumbnailers/webp.thumbnailer" ''
        [Thumbnailer Entry]
        MimeType=image/webp
        Exec=${thumbnailerScript '' exec ${imagemagick}/bin/convert -thumbnail "$s" "$i" "$o" ''}
      '')
      (python3ScriptWithDeps "dbus-make-thumbnails" ./dbus-make-thumbnails.py (ps:
        with ps; [ dbus-python pygobject3 pyxdg ]))
    ];

    xdg.configFile = {
      "xfce4/xfconf/xfce-perchannel-xml/thunar.xml" = {
        source = utils.mkMutableSymlink ./thunar.xml;
        force = true;
      };
      "Thunar/uca.xml".source = utils.mkMutableSymlink ./uca.xml;
      "tumbler/tumbler.rc".source = ./tumbler.rc;
    };
  };
}
