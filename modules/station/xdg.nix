{ config, syncedFolders, utils, pkgs, ... }: {
  hm = {
    home.packages = with pkgs; [ xdg-user-dirs ];

    xdg = {
      enable = true;

      userDirs = {
        enable = true;

        desktop     = config.my.home;
        download    = config.my.home;
        documents   = config.my.home;
        templates   = config.my.home;
        music       = syncedFolders.music.path;
        pictures    = syncedFolders.pictures.path;
        videos      = "${config.my.home}/videos";
        publicShare = "${config.my.home}/public";
      };

      # TODO force?
      configFile."mimeapps.list".source = utils.mkMutableSymlink ./mimeapps.list;
    };
  };
}
