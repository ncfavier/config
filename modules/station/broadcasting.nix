{ lib, config, pkgs, ... }: with lib; mkEnableModule [ "broadcasting" ] {
  hm.programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-vkcapture
    ] ++ optional (config.sound.backend == "pipewire") obs-pipewire-audio-capture;
  };
}
