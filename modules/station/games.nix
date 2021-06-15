{ config, syncedFolders, pkgs, ... }: {
  hm = {
    home.packages = with pkgs; [
      teeworlds
      dwarf-fortress
      minecraft
    ];

    xdg.dataFile."df_linux/data/save".source = config.hm.lib.file.mkOutOfStoreSymlink "${syncedFolders.saves.path}/df";
  };
}
