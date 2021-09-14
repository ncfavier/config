{ lib, config, pkgs, ... }: with lib; {
  hm = {
    programs.rofi = with config.theme; {
      enable = true;
      package = with pkgs; rofi.override {
        symlink-dmenu = true;
        plugins = [
          rofi-calc
          rofi-emoji
          rofi-file-browser
        ];
      };

      font = pangoFont;

      theme = with config.hm.lib.formats.rasi; {
        " @theme" = "default"; # space to make sure it's the first line
        "*" = {
          background = mkLiteral background;
          lightbg = mkLiteral background;
          foreground = mkLiteral foreground;
          lightfg = mkLiteral foreground;
          red = mkLiteral hot;
          blue = mkLiteral cold;
          border-color = mkLiteral borderColor;
        };
        window = {
          inherit padding;
          border = borderWidth;
        };
        element-icon.size = mkLiteral "2em";
        element-text.vertical-align = mkLiteral "0.5";
        button.horizontal-align = mkLiteral "0.5";
        message.border = 0;
        listview.border = 0;
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
