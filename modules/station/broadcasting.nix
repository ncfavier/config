{ lib, pkgs, ... }: with lib; mkEnableModule [ "broadcasting" ] {
  hm.programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-vkcapture
      obs-pipewire-audio-capture
    ];
  };
}
