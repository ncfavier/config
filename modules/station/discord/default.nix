{ lib, config, pkgs, ... }: with lib; {
  hm.home.packages = with pkgs; [
    (config.lib.x.scaleElectronApp (pkgs.mine "discord-cli-args" "sha256-TCVRpIXM8N7t4vybjBQ2CyAWnsL8Z1tpcEUmKGLtsl4=").discord) # TODO
  ];
  hm.xdg.configFile."discord/settings.json".source =
    config.lib.meta.mkMutableSymlink ./settings.json;

  nixpkgs.config.allowUnfree = true;
}
