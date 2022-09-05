{ lib, config, pkgs, ... }: with lib; {
  hm.home.packages = with pkgs; [ discord ];
  hm.xdg.configFile."discord/settings.json".source =
    config.lib.meta.mkMutableSymlink ./settings.json;
}
