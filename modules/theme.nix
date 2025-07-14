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
      black          = "#000000";
      darkGrey       = if dark then "#666666" else "#aaaaaa";
      lightGrey      = if dark then "#444444" else "#cccccc";
      white          = "#ffffff";
      hot            = "#d13cff";
      cold           = if dark then "#4befdb" else "#33aacc";
      background     = if dark then black else white;
      foreground     = if dark then white else black;
      backgroundAlt  = darkGrey;
      foregroundAlt  = lightGrey;
      borderWidth    = 0;
      borderColor    = foreground;
      borderColorAlt = foregroundAlt;
      barHeight      = 28;
      padding        = 16;
      font           = "sans-serif";
      fontSize       = 10;
      pangoFont      = "${font} ${toString fontSize}";
    };

    lib.shellEnv.theme = config.theme;
    lib.x.dpiScale = n: builtins.floor (n * config.services.xserver.dpiScaleFactor);
  };
}
