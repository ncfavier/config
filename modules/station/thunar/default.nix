{ lib, config, pkgs, ... }: with lib; {
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  programs.dconf.enable = true;
  programs.file-roller.enable = true;

  hm = {
    home.packages = with pkgs; let
      thumbnailerScript = name: script: "${writeShellScript "${name}-script" ''
        o=$1 s=$2 i=$3
        if [[ $i != /* ]]; then
          [[ $i == trash://* ]] &&
              i=file://''${XDG_DATA_HOME:-~/.local/share}/Trash/files''${i#trash://}
          i=''${i#file://}
          printf -v i %b "''${i//%/'\x'}"
        fi
        ${script}
      ''} %o %s %i %u";
    in [
      (xfce.thunar.override {
        thunarPlugins = with xfce; [
          thunar-volman
          thunar-archive-plugin
          thunar-media-tags-plugin
        ];
      })
      xfce.xfconf
      glib.bin
      gnome.zenity
      webp-pixbuf-loader
      (pr 244723 "sha256-qtFhiU/LtZrxpWyBMe3kto5QAe2BnVKQeADwProxNHs=").libavif # TODO
      (writeTextDir "share/thumbnailers/ffmpegthumbnailer.thumbnailer" ''
        [Thumbnailer Entry]
        MimeType=${concatStringsSep ";" config.lib.mimeTypes.media}
        Exec=${thumbnailerScript "ffmpeg" ''${ffmpegthumbnailer}/bin/ffmpegthumbnailer -i "$i" -o "$o" -s "$s" -t 30 -m''}
      '')
      (pythonScriptWithDeps "dbus-gen-thumbnails" ./dbus-gen-thumbnails.py (ps:
        with ps; [ dbus-python pygobject3 pyxdg ]))
    ];

    xdg.configFile = {
      "xfce4/xfconf/xfce-perchannel-xml/thunar.xml" = {
        source = ./thunar.xml;
        force = true;
      };
      "Thunar/uca.xml".source = config.lib.meta.mkMutableSymlink ./uca.xml;
      "Thunar/accels.scm".source = config.lib.meta.mkMutableSymlink ./accels.scm;
      "tumbler/tumbler.rc" = {
        source = ./tumbler.rc;
        onChange = ''
          pkill ''${VERBOSE+-e} -f ${pkgs.xfce.tumbler} || true
        '';
      };
    };
  };
}
