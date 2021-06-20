{ lib, pkgs, ... }: with lib; {
  hm = {
    programs.rofi = with theme; {
      enable = true;
      package = with pkgs; rofi.override {
        symlink-dmenu = true;
        plugins = [
          rofi-calc
          rofi-emoji
          rofi-file-browser
        ];
      };

      inherit padding;
      borderWidth = 1;
      font = pangoFont;

      colors = let
        transparent = "#00000000";
      in {
        window = {
          background = black;
          border = borderColor;
          separator = transparent;
        };
        rows = rec {
          normal = {
            background = transparent;
            foreground = white;
            backgroundAlt = transparent;
            highlight.background = white;
            highlight.foreground = black;
          };
          active = recursiveUpdate normal {
            foreground = cold;
            highlight.background = cold;
          };
          urgent = recursiveUpdate normal {
            foreground = hot;
            highlight.background = hot;
          };
        };
      };

      cycle = true;
      terminal = "alacritty";

      extraConfig = {
        drun-display-format = "{name}";
        sort = true;
        sorting-method = "fzf";
        kb-mode-next = "Super+space,Control+Tab";
        kb-mode-previous = "Super+Shift+space,Control+ISO_Left_Tab";
      };
    };
  };
}
