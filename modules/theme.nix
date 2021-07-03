{ theme, ... }: {
  _module.args.theme = rec {
    dark = true;
    font = "bitmap";
    pangoFont = "${font} 8";
    black     = "#0b000d";
    darkGrey  = if dark then "#444444" else "#aaaaaa";
    lightGrey = if dark then "#666666" else "#cccccc";
    white     = "#ffffff";
    hot       = "#ff00cc";
    cold      = if dark then "#4bebef"else "#33aacc";
    background = if dark then black else white;
    foreground = if dark then white else black;
    backgroundAlt = darkGrey;
    foregroundAlt = lightGrey;
    borderWidth = 0;
    borderColor = foreground;
    padding = 16;
    gtkTheme = "Flat-Remix-GTK-Blue" + (if dark then "-Darkest" else "");
    iconTheme = "Flat-Remix-Blue";
  };

  lib.shellEnv = {
    inherit theme;
  };

  # specialisation.light.configuration = {
  #   _module.args.theme.dark = false;
  # };
}
