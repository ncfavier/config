{ lib, config, pkgs, ... }: with lib; {
  hm.services.dunst = {
    enable = true;
    package = pkgs.dunst.overrideAttrs (o: {
      version = "unstable";
      src = pkgs.fetchFromGitHub {
        owner = "dunst-project";
        repo = "dunst";
        rev = "6c9f83bcdd8e9eb5d81c3f6c43e2dfa5afd72fe7";
        sha256 = "sha256-hGsSPNODNPgGoZZAvAXo8OzFsOvn9bFwa0p1VMWfpTE=";
      };
    });

    settings = with config.theme; rec {
      global = {
        enable_recursive_icon_lookup = true;
        width = "(0, 1200)";
        height = 9999;
        offset = "${toString (padding * 2)}x${toString (barHeight + padding * 2)}";
        notification_limit = 6;
        shrink = true;
        inherit padding;
        horizontal_padding = padding;
        frame_width = 1;
        frame_color = borderColor;
        separator_color = "frame";
        font = pangoFont;
        markup = "full";
        format = "<b>%s</b>\\n%b %p";
        word_wrap = true;
        icon_theme = config.hm.gtk.iconTheme.name;
        icon_position = "right";
        min_icon_size = 64;
        max_icon_size = 500;
        dmenu = "rofi -dmenu -p dunst -no-fixed-num-lines";
        browser = "xdg-open";
        mouse_right_click = "context";
        show_indicators = false;
      };

      urgency_low = urgency_normal;

      urgency_normal = {
        inherit background foreground;
        timeout = 10;
      };

      urgency_critical = {
        background = hot;
        inherit foreground;
        timeout = 0;
      };
    };
  };
}
