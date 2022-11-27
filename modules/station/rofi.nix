{ lib, config, pkgs, pkgsPR, ... }: with lib; {
  nixpkgs.overlays = [ (self: super: {
    rofi-unwrapped = super.rofi-unwrapped.overrideAttrs (o: {
      patches = o.patches or [] ++ [
        (pkgs.fetchpatch {
          url = "https://github.com/davatorium/rofi/commit/0f097f29988078ddae2799f6c3ab5beb81aaafc3.patch";
          hash = "sha256-7DAt61kfuLrn+Ca5Te51225euNVo37ElZHVkht9hHA0=";
        })
      ];
    });
  }) ];

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

    home.packages = [ (pkgsPR 202516 "sha256-jp/LHQUs1x9PXXKHTZ2i1QHlDPevmZj2ySg1Ss2SX5w=").rofimoji ];

    xdg.configFile."rofimoji.rc".text = ''
      skin-tone = neutral
      max-recent = 0
    '';
  };
}
