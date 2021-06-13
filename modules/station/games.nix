{ config, pkgs, syncedFolders, ... }: {
  myHm = {
    home.packages = with pkgs; [
      teeworlds
      dwarf-fortress
      minecraft
    ];

    xdg.dataFile."df_linux/data/save".source = config.myHm.lib.file.mkOutOfStoreSymlink "${syncedFolders.saves.path}/df";
  };
}
