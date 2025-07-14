{ inputs, lib, config, pkgs, ...}: with lib; {
  cachix.derivationsToPush = [ config.hm.programs.ghostty.package ];

  hm.programs.ghostty = {
    enable = true;
    package = inputs.ghostty.packages.x86_64-linux.default.overrideAttrs (old: {
      patches = old.patches or [] ++ [
        (pkgs.fetchpatch {
          url = "https://github.com/Opposite34/ghostty/commit/5b871c595254eece6bf44ab48f71409b7ed36088.patch";
          hash = "sha256-hCWp2MdoD89oYN3I+Pq/HW4k4RcozS1tDuXHO3Nd+Y8=";
        })
      ];
    });
    installVimSyntax = true;

    settings = with config.theme; {
      gtk-single-instance = true;
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
      shell-integration-features = "no-cursor";
      mouse-hide-while-typing = true;
      mouse-scroll-multiplier = 2;
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
