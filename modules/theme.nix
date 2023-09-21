{ lib, config, ... }: with lib; {
  options.theme = mkOption {
    type = with types; submodule {
      freeformType = attrs;
      options.dark = mkOption {
        type = bool;
        default = true;
      };
    };
  };

  config = {
    theme = with config.theme; {
      black         = "#000000";
      darkGrey      = if dark then "#666666" else "#aaaaaa";
      lightGrey     = if dark then "#444444" else "#cccccc";
      white         = "#ffffff";
      hot           = "#ff00ff";
      cold          = if dark then "#4befdb" else "#33aacc";
      background    = if dark then black else white;
      foreground    = if dark then white else black;
      backgroundAlt = darkGrey;
      foregroundAlt = lightGrey;
      borderWidth = 0;
      borderColor = foreground;
      padding = 16;
      barHeight = if config.services.xserver.dpi != null && config.services.xserver.dpi > 100 then 32 else 28;
      gtkTheme = "Flat-Remix-GTK" + (if dark then "-Violet-Darkest" else "-Black-Light");
      iconTheme = "Flat-Remix-Violet" + (if dark then "-Dark" else "-Light");
      gtkFont = "sans-serif";
      font = "bitmap";
      fontSize = 8;
      pangoFont = "${font} ${toString fontSize}";
    };

    lib.shellEnv.theme = config.theme;
  };
}
