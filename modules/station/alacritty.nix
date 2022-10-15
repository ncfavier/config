{ lib, config, pkgs, ... }: with lib; {
  hm.programs.alacritty = {
    enable = true;
    settings = with config.theme; {
      window = {
        dimensions = {
          columns = 80;
          lines = 25;
        };
        padding = let
          inherit (config.services.xserver) dpi;
          padding' = if dpi != null then padding * 96 / dpi else padding; # undo DPI scaling
        in {
          x = padding';
          y = padding';
        };
        decorations = "none";
      };
      font = {
        normal.family = "bitmap";
        size = 8;
      };
      colors = {
        primary = {
          inherit background foreground;
        };
        normal = {
          black   = background;
          red     = hot;
          green   = cold;
          yellow  = hot;
          blue    = cold;
          magenta = hot;
          cyan    = cold;
          white   = foregroundAlt;
        };
        bright = {
          black   = backgroundAlt;
          red     = hot;
          green   = cold;
          yellow  = hot;
          blue    = cold;
          magenta = hot;
          cyan    = cold;
          white   = foreground;
        };
      };
      selection.save_to_clipboard = true;
      cursor.style.blinking = "Always";
      key_bindings = [
        { key =  3; mods = "Alt"; chars = "\\e2"; }
        { key =  8; mods = "Alt"; chars = "\\e7"; }
        { key = 10; mods = "Alt"; chars = "\\e9"; }
        { key = 11; mods = "Alt"; chars = "\\e0"; }
      ];
    };
  };
}
