{ config, pkgs, syncedFolders, ... }: {
  services.dbus.packages = [ pkgs.dconf ];

  myHm = {
    home.packages = [ pkgs.lxappearance ];

    gtk = {
      enable = true;
      gtk2 = {
        configLocation = "${config.myHm.xdg.configHome}/gtk-2.0/gtkrc";
      };
      gtk3 = {
        bookmarks = [
          "file://${config.my.home}/git"
          "file://${syncedFolders.my.path}"
          "file://${syncedFolders.pictures.path}"
          "file://${syncedFolders.music.path}"
          "file://${config.my.home}/videos"
        ];
        extraConfig = {
          gtk-button-images = true;
          gtk-menu-images = true;
          gtk-xft-antialias = true;
          gtk-xft-hinting = true;
          gtk-application-prefer-dark-theme = true;
        };
      };
      font = {
        name = "sans-serif";
        size = 10;
      };
      theme = {
        package = pkgs.flat-remix-gtk;
        name = "Flat-Remix-GTK-Blue-Darkest";
      };
      iconTheme = {
        package = pkgs.flat-remix-icon-theme;
        name = "Flat-Remix-Blue-Dark";
      };
    };
  };
}
