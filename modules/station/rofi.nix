{ lib, config, pkgs, ... }: with lib; {
  hm = {
    programs.rofi = with config.theme; {
      enable = true;
      package = with pkgs; rofi.override {
        symlink-dmenu = true;
        plugins = [
          rofi-calc
        ];
      };

      font = pangoFont;

      theme = with config.hm.lib.formats.rasi; {
        "@import" = "default";
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
        message.border = 0;
        listview.border = 0;
        inputbar.children = mkLiteral "[ prompt,textbox-prompt-colon,entry,num-filtered-rows,textbox-num-sep,num-rows ]";
        entry.placeholder = "";
        element-icon.size = mkLiteral "2em";
        element-text.vertical-align = mkLiteral "0.5";
        button.horizontal-align = mkLiteral "0.5";
      };

      cycle = true;
      terminal = "alacritty";

      pass = {
        enable = true;
        extraConfig = ''
          default_do=copyPass
          clip=clipboard
        '';
      };

      extraConfig = {
        dpi = 0; # auto-detect using X screen size
        drun-display-format = "{name}";
        sort = true;
        normalize-match = true;
        sorting-method = "fzf";
        kb-mode-next = "Super+space,Control+Tab";
        kb-mode-previous = "Super+Shift+space,Control+ISO_Left_Tab";
      };
    };

    home.packages = with pkgs; [ rofimoji ];

    xdg.configFile."rofimoji.rc".text = ''
      skin-tone = neutral
      max-recent = 0
    '';
  };
}
