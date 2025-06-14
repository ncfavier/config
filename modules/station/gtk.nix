{ lib, config, pkgs, ... }: with lib; {
  hm = {
    home.packages = [
      pkgs.lxappearance
      pkgs.gtk3.dev # gtk3-icon-browser
    ];

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
          gtk-recent-files-enabled = false;
        };
      };
      font = {
        name = gtkFont;
        size = 10;
      };
      theme = {
        package = pkgs.orchis-theme.override {
          tweaks = [ "black" "primary" ];
        };
        name = gtkTheme;
      };
      iconTheme = {
        package = pkgs.tela-icon-theme;
        name = iconTheme;
      };
    };

    xdg.configFile."gtk-3.0/settings.ini".force = true;
    xdg.configFile."gtk-3.0/bookmarks".force = true;

    home.pointerCursor.gtk.enable = true;

    # live reloading
    services.xsettingsd = {
      enable = true;
      settings = {
        "Net/ThemeName" = mkIf (config.hm.gtk.theme != null) config.hm.gtk.theme.name;
        "Net/IconThemeName" = mkIf (config.hm.gtk.iconTheme != null) config.hm.gtk.iconTheme.name;
      };
    };
  };
}
