{ lib, config, pkgs, ... }: with lib; {
  hm = {
    home.packages = [ pkgs.lxappearance ];

    gtk = with config.theme; {
      enable = true;
      gtk2 = {
        configLocation = "${config.hm.xdg.configHome}/gtk-2.0/gtkrc";
      };
      gtk3 = {
        bookmarks = [
          "file://${config.my.home}/my"
          "file://${config.my.home}/git"
          "file://${config.hm.xdg.userDirs.pictures}"
          "file://${config.hm.xdg.userDirs.music}"
          "file://${config.hm.xdg.userDirs.videos}"
        ];
        extraConfig = {
          gtk-button-images = true;
          gtk-menu-images = true;
          gtk-xft-antialias = 1;
          gtk-xft-hinting = 1;
        };
      };
      font = {
        name = gtkFont;
        size = 10;
      };
      theme = {
        package = pkgs.flat-remix-gtk;
        name = gtkTheme;
      };
      iconTheme = {
        package = pkgs.flat-remix-icon-theme;
        name = iconTheme;
      };
    };

    xdg.configFile."gtk-3.0/settings.ini".force = true;
    xdg.configFile."gtk-3.0/bookmarks".force = true;
    home.file.".icons/default/index.theme".force = true;

    home.pointerCursor.gtk.enable = true;

    # live reloading
    services.xsettingsd = {
      enable = true;
      settings = {
        "Net/ThemeName" = config.hm.gtk.theme.name;
        "Net/IconThemeName" = config.hm.gtk.iconTheme.name;
      };
    };
  };
}
