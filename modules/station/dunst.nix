{ lib, config, pkgs, ... }: with lib; {
  hm.home.packages = [ pkgs.libnotify ];

  hm.services.dunst = {
    enable = true;

    settings = with config.theme; rec {
      global = {
        enable_recursive_icon_lookup = true;
        width = "(0, 1200)";
        height = "(0, 9999)";
        offset = "(${toString (padding * 2)}, ${toString (barHeight + padding * 2)})";
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

      dunstify = {
        appname = "dunstify";
        override_pause_level = 100;
        min_icon_size = 32;
      };
      wifi = {
        appname = "NetworkManager Applet";
        override_pause_level = 100;
        min_icon_size = 24;
      };
      bluetooth = {
        appname = "blueman";
        override_pause_level = 100;
      };
    };
  };
}
