{ lib, config, utils, pkgs, ... }: with lib; {
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  programs.dconf.enable = true;
  programs.file-roller.enable = true;

  # https://github.com/NixOS/nixpkgs/pull/126832
  environment.sessionVariables.GIO_EXTRA_MODULES = "${config.services.gvfs.package}/lib/gio/modules";
  environment.variables.GIO_EXTRA_MODULES = mkForce config.environment.sessionVariables.GIO_EXTRA_MODULES;

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
      gnome.zenity
      (linkFarm "glib-default-terminal" [ {
        # workaround for https://gitlab.gnome.org/GNOME/glib/-/issues/338
        name = "bin/tilix";
        path = "${alacritty}/bin/alacritty";
      } ])
      (writeTextDir "share/thumbnailers/ffmpegthumbnailer.thumbnailer" ''
        [Thumbnailer Entry]
        MimeType=${concatStringsSep ";" config.lib.mimeTypes.media}
        Exec=${thumbnailerScript "ffmpeg" ''${ffmpegthumbnailer}/bin/ffmpegthumbnailer -i "$i" -o "$o" -s "$s" -m''}
      '')
      (writeTextDir "share/thumbnailers/webp.thumbnailer" ''
        [Thumbnailer Entry]
        MimeType=image/webp
        Exec=${thumbnailerScript "webp" ''${imagemagick}/bin/convert -thumbnail "$s" "$i" "$o"''}
      '')
      (python3ScriptWithDeps "dbus-gen-thumbnails" ./dbus-gen-thumbnails.py (ps:
        with ps; [ dbus-python pygobject3 pyxdg ]))
    ];

    xdg.configFile = {
      "xfce4/xfconf/xfce-perchannel-xml/thunar.xml" = {
        source = utils.mkMutableSymlink ./thunar.xml;
        force = true;
      };
      "Thunar/uca.xml".source = utils.mkMutableSymlink ./uca.xml;
      "Thunar/accels.scm".source = utils.mkMutableSymlink ./accels.scm;
      "tumbler/tumbler.rc".source = ./tumbler.rc;
    };
  };
}
