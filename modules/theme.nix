{ lib, config, theme, ... }: with lib; {
  options.theme = mkOption {
    type = with types; submodule {
      options.dark = mkOption {
        type = bool;
        default = true;
      };
      freeformType = attrs;
    };
  };

  config = {
    theme = with theme; {
      black         = "#000000";
      darkGrey      = if dark then "#444444" else "#aaaaaa";
      lightGrey     = if dark then "#666666" else "#cccccc";
      white         = "#ffffff";
      hot           = "#ff00cc";
      cold          = if dark then "#4bebef" else "#33aacc";
      background    = if dark then black else white;
      foreground    = if dark then white else black;
      backgroundAlt = darkGrey;
      foregroundAlt = lightGrey;
      borderWidth = 0;
      borderColor = foreground;
      padding = 16;
      gtkTheme = "Flat-Remix-GTK-Blue" + (if dark then "-Darkest" else "");
      iconTheme = "Flat-Remix-Blue";
      font = "bitmap";
      pangoFont = "${font} 8";
    };

    _module.args = { inherit (config) theme; };

    lib.shellEnv = { inherit theme; };

    # specialisation.light.configuration = {
    #   theme.dark = false;
    # };
  };
}
