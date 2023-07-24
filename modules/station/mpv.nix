{ lib, config, pkgs, ... }: with lib; {
  hm = {
    programs.mpv = {
      enable = true;
      package = pkgs.mpv.override {
        scripts = with pkgs.mpvScripts; [
          autoload
          mpris
          quality-menu
        ];
      };

      config = {
        autofit = "80%x80%";
        force-window = true;
        volume-max = 200;
        sub-auto = "fuzzy";
        sub-border-size = 1;

        pulse-latency-hacks = mkIf (config.sound.backend == "pulseaudio") true;
      };

      profiles = {
        "loop" = {
          loop-file = "inf";
          profile-cond = "p.duration<=20";
        };
      };

      bindings = {
        "Alt+h" = "add video-pan-x 0.01";
        "Alt+l" = "add video-pan-x -0.01";
        "Alt+k" = "add video-pan-y 0.01";
        "Alt+j" = "add video-pan-y -0.01";
        "b" = ''cycle-values background "#000000" "#ffffff"'';
        "F" = "script-binding quality_menu/video_formats_toggle";
        "Alt+f" = "script-binding quality_menu/audio_formats_toggle";
      };
    };

    home.packages = with pkgs; [
      syncplay
    ];
  };
}
