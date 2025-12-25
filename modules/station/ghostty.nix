{ inputs, lib, config, pkgs, ...}: with lib; {
  hm.programs.ghostty = {
    enable = true;
    package = pkgs.ghostty;
    installVimSyntax = true;

    settings = with config.theme; {
      gtk-single-instance = true;
      window-inherit-working-directory = false;
      window-decoration = false;
      font-family = [ "monospace" "emoji" ];
      font-size = fontSize;
      font-codepoint-map = "U+2600-U+27BF,U+2B00-U+2BFF,U+1F300-U+1F5FF=emoji";
      window-title-font-family = "monospace";
      window-padding-x = padding;
      window-padding-y = padding;
      theme = "Aura";
      cursor-style = "block";
      cursor-color = "white";
      scrollback-limit = 50000000;
      shell-integration-features = "no-cursor";
      mouse-hide-while-typing = true;
      mouse-scroll-multiplier = 2;
      clipboard-read = "ask";
      clipboard-write = "allow";
      copy-on-select = "clipboard";
      app-notifications = [ "no-clipboard-copy" ];
      bell-features = [ "attention,no-title" ];
      keybind = map (n: "alt+digit_${toString n}=esc:${toString n}") (range 0 9); # https://github.com/ghostty-org/ghostty/issues/7110

      background = background;
      foreground = foreground;
      cursor-text = background;
      selection-background = hot;
      palette = [
        "0=${background}"
        "1=${hot}"
        "2=${cold}"
        "3=${hot}"
        "4=${cold}"
        "5=${hot}"
        "6=${cold}"
        "7=${foregroundAlt}"
        "8=${backgroundAlt}"
        "9=${hot}"
        "10=${cold}"
        "11=${hot}"
        "12=${cold}"
        "13=${hot}"
        "14=${cold}"
        "15=${foreground}"
      ];

      gtk-custom-css = "${pkgs.writeText "ghostty.css" ''
        window {
          border-radius: 0 0;
        }
      ''}";
    };
  };
}
