{ pkgs, ... }: {
  hm = {
    programs.mpv = {
      enable = true;
      package = pkgs.mpv-with-scripts.override {
        scripts = with pkgs.mpvScripts; [
          autoload
        ];
      };

      config = {
        autofit = "0x500";
        sub-auto = "fuzzy";
      };

      profiles = {
        "extension.gif" = {
          loop-file = "inf";
        };
        "extension.gifv" = {
          profile = "extension.gif";
        };
      };

      bindings = {
        "Alt+h" = "add video-pan-x 0.01";
        "Alt+l" = "add video-pan-x -0.01";
        "Alt+k" = "add video-pan-y 0.01";
        "Alt+j" = "add video-pan-y -0.01";
        "b" = '' cycle-values background "#000000" "#ffffff" '';
      };
    };

    home.packages = with pkgs; [
      syncplay
    ];
  };
}
