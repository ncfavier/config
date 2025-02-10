{ lib, config, pkgs, ... }: with lib; {
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  programs.dconf.enable = true;
  programs.file-roller.enable = true;

  hm = {
    home.packages = with pkgs; let
      thumbnailerScript = name: script: "${writeShellScript "${name}-script" ''
        o=$1 s=$2 i=$3 u=$4
        if [[ $i != /* ]]; then
          i=$u
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
      xfce.exo
      glib
      zenity
      webp-pixbuf-loader
      libavif
      (writeShellScriptBin "closest-dir" ''
        if [[ -d $1 ]]; then
          printf '%s\n' "$1"
        else
          printf '%s\n' "''${1%/*}"
        fi
      '')
      (writeTextDir "share/thumbnailers/ffmpegthumbnailer.thumbnailer" ''
        [Thumbnailer Entry]
        MimeType=${concatStringsSep ";" config.lib.mimeTypes.media}
        Exec=${thumbnailerScript "ffmpeg" ''${ffmpegthumbnailer}/bin/ffmpegthumbnailer -i "$i" -o "$o" -s "$s" -t 30 -m''}
      '')
      ((pythonScriptWithDeps "dbus-gen-thumbnails" ./dbus-gen-thumbnails.py (ps:
        with ps; [ dbus-python pygobject3 pyxdg ])).overrideAttrs {
          nativeBuildInputs = [ wrapGAppsNoGuiHook gobject-introspection ];
      })
    ];

    xfconf.settings.thunar = {
      hidden-bookmarks = [ "recent:///" ];
      last-icon-view-zoom-level = "THUNAR_ZOOM_LEVEL_400_PERCENT";
      last-menubar-visible = false;
      misc-change-window-icon = true;
      misc-date-style = "THUNAR_DATE_STYLE_LONG";
      misc-exec-shell-scripts-by-default = true;
      misc-file-size-binary = true;
      misc-full-path-in-tab-title = true;
      misc-middle-click-in-tab = true;
      misc-show-delete-action = true;
      misc-single-click = false;
      misc-text-beside-icons = false;
      misc-thumbnail-draw-frames = false;
      misc-thumbnail-mode = "THUNAR_THUMBNAIL_MODE_ALWAYS";
      shortcuts-icon-emblems = false;
      shortcuts-icon-size = "THUNAR_ICON_SIZE_48";
      tree-icon-size = "THUNAR_ICON_SIZE_32";
    };

    xdg.configFile = {
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
