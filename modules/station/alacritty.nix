{ lib, config, ... }: with lib; {
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
        normal.family = "monospace";
        size = fontSize;
      };
      colors = {
        draw_bold_text_with_bright_colors = true;
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
      cursor = {
        style.blinking = "Always";
        blink_timeout = 0;
      };
      keyboard.bindings = let
        # https://github.com/nix-community/home-manager/pull/611#discussion_r1115932168
        # https://github.com/nix-community/home-manager/pull/4817#discussion_r1441726084
        esc = (builtins.fromTOML ''c = "\u001b"'').c;
      in [
        { key =  3; mods = "Alt"; chars = "${esc}2"; }
        { key =  8; mods = "Alt"; chars = "${esc}7"; }
        { key = 10; mods = "Alt"; chars = "${esc}9"; }
        { key = 11; mods = "Alt"; chars = "${esc}0"; }
      ];
    };
  };
}
