{ lib, config, pkgs, ... }: with lib; let
  thunarWithPkgs = pkgs.thunar.override {
    thunarPlugins = with pkgs; [
      thunar-volman
      thunar-archive-plugin
    ];
  };
in {
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  programs.dconf.enable = true;

  cachix.derivationsToPush = [ thunarWithPkgs pkgs.tumbler ];

  nixpkgs.overlays = [ (self: super: {
    tumbler = super.tumbler.overrideAttrs (drv: {
      patches = drv.patches or [] ++ [
        ./tumbler-thumbnail-symlinks.patch
      ];
    });

    thunar-unwrapped = super.thunar-unwrapped.overrideAttrs (drv: {
      patches = drv.patches or [] ++ [
        # https://gitlab.xfce.org/xfce/thunar/-/merge_requests/671
        (builtins.toFile "thunar-compact.patch" ''
diff --git a/thunar/thunar-icon-view.c b/thunar/thunar-icon-view.c
index 218601800..b03ef6ed9 100644
--- a/thunar/thunar-icon-view.c
+++ b/thunar/thunar-icon-view.c
@@ -212 +212 @@ thunar_icon_view_set_consistent_horizontal_spacing (ThunarIconView *icon_view)
-  if (exo_icon_view_get_orientation (exo_icon_view) == GTK_ORIENTATION_HORIZONTAL)
+  if (TRUE || exo_icon_view_get_orientation (exo_icon_view) == GTK_ORIENTATION_HORIZONTAL)
        '')
        ./thunar-thumbnail-symlinks.patch
      ];
    });
  }) ];

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
      thunarWithPkgs
      xfconf
      exo
      glib
      file-roller
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
      last-menubar-visible = false;
      misc-change-window-icon = true;
      misc-date-style = "THUNAR_DATE_STYLE_LONG";
      misc-exec-shell-scripts-by-default = true;
      misc-file-size-binary = true;
      misc-full-path-in-tab-title = true;
      misc-middle-click-in-tab = true;
      misc-show-delete-action = true;
      misc-single-click = false;
      misc-symbolic-icons-in-toolbar = false;
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
          ${getBin pkgs.procps}/bin/pkill ''${VERBOSE+-e} -f ${pkgs.tumbler} || true
        '';
      };
    };
  };
}
