{ lib, config, pkgs, pkgsRev, ... }: with lib; {
  hm.services.dunst = {
    enable = true;
    package = (pkgsRev "c82b46413401efa740a0b994f52e9903a4f6dcd5" "13s8g6p0gzpa1q6mwc2fj2v451dsars67m4mwciimgfwhdlxx0bk").dunst;

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
