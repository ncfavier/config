{ inputs, lib, config, pkgs, ...}: with lib; {
  hm.programs.ghostty = {
    enable = true;
    package = inputs.ghostty.packages.x86_64-linux.default;
    installVimSyntax = true;

    settings = with config.theme; {
      gtk-single-instance = true;
      window-decoration = false;
      font-family = [ "monospace" "emoji" ];
      font-codepoint-map = "U+2600-U+27BF,U+2B00-U+2BFF,U+1F300-U+1F5FF=emoji";
      window-title-font-family = "monospace";
      window-padding-x = 16;
      window-padding-y = 16;
      theme = "Aura";
      cursor-style = "block";
      cursor-color = "white";
      shell-integration-features = "no-cursor";
      mouse-hide-while-typing = true;
      copy-on-select = "clipboard";
      app-notifications = [ "no-clipboard-copy" ];
      keybind = [
        "alt+é=esc:é"
        "alt+è=esc:è"
        "alt+ç=esc:ç"
        "alt+à=esc:à"
      ];

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
