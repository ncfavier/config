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
      hot           = "#d13cff";
      cold          = if dark then "#4befdb" else "#33aacc";
      background    = if dark then black else white;
      foreground    = if dark then white else black;
      backgroundAlt = darkGrey;
      foregroundAlt = lightGrey;
      borderWidth = 0;
      borderColor = foreground;
      dpi = if config.services.xserver.dpi == null then 96 else config.services.xserver.dpi;
      dpiScale = dpi / 96.0;
      padding = 16;
      baseBarHeight = 28;
      barHeight = builtins.floor (baseBarHeight * dpiScale);
      gtkTheme = "Orchis-Purple" + (if dark then "-Dark" else "");
      iconTheme = "Tela-dracula" + (if dark then "-dark" else "");
      gtkFont = "sans-serif";
      font = "sans-serif";
      fontSize = 10;
      # pangoFont = "${font} ${toString fontSize}";
      pangoFont = "sans-serif 12";
      trayWidth = 3 * barHeight;
    };

    lib.shellEnv.theme = config.theme;
  };
}
