{ lib, config, theme, pkgs, ... }: with lib; {
  hm.services.dunst = {
    enable = true;

    settings = with theme; rec {
      global = {
        geometry = "800x5-32+64";
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
        icon_position = "right";
        min_icon_size = 64;
        max_icon_size = 256;
        dmenu = "rofi -dmenu -p dunst";
        browser = "xdg-open";
        mouse_right_click = "context";
        show_indicators = false;
        icon_path = concatMapStringsSep ":" (p: "${config.hm.gtk.iconTheme.package}/share/icons/${config.hm.gtk.iconTheme.name}/${p}") [
          "actions/scalable"
          "actions/symbolic"
          "animations"
          "apps/scalable"
          "apps/symbolic"
          "categories/scalable"
          "categories/symbolic"
          "devices/scalable"
          "devices/symbolic"
          "emblems/scalable"
          "emblems/symbolic"
          "emotes"
          "mimetypes/scalable"
          "mimetypes/symbolic"
          "panel"
          "places/scalable"
          "places/symbolic"
          "status/scalable/16"
          "status/scalable/32"
          "status/scalable/512"
          "status/symbolic"
        ];
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
