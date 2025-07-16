{ lib, config, pkgs, ... }: with lib; {
  hm.home.packages = with pkgs; [
    (config.lib.x.scaleElectronApp pkgs.discord-cli-args.discord)
  ];
  hm.xdg.configFile."discord/settings.json".source =
    config.lib.meta.mkMutableSymlink ./settings.json;

  nixpkgs.config.allowUnfree = true;
}
