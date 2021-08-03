{ lib, config, pkgs, ... }: with lib; {
  hm = {
    home.packages = [ pkgs.lxappearance ];

    gtk = {
      enable = true;
      gtk2 = {
        configLocation = "${config.hm.xdg.configHome}/gtk-2.0/gtkrc";
      };
      gtk3 = {
        bookmarks = [
          "file://${config.my.home}/git"
          "file://${config.synced.my.path}"
          "file://${config.synced.pictures.path}"
          "file://${config.synced.music.path}"
          "file://${config.my.home}/videos"
        ];
        extraConfig = {
          gtk-button-images = true;
          gtk-menu-images = true;
          gtk-xft-antialias = 1;
          gtk-xft-hinting = 1;
        };
      };
      font = {
        name = "sans-serif";
        size = 10;
      };
      theme = {
        package = pkgs.flat-remix-gtk;
        name = config.theme.gtkTheme;
      };
      iconTheme = {
        package = pkgs.flat-remix-icon-theme;
        name = config.theme.iconTheme;
      };
    };

    xdg.configFile = {
      "gtk-3.0/settings.ini".force = true;

      # live reloading
      "xsettingsd/xsettingsd.conf" = {
        text = ''
          Net/ThemeName "${config.hm.gtk.theme.name}"
          Net/IconThemeName "${config.hm.gtk.iconTheme.name}"
        '';
        onChange = ''
          timeout 3s ${pkgs.xsettingsd}/bin/xsettingsd 2> /dev/null &
        '';
      };
    };
  };
}
