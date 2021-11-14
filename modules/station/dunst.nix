{ lib, config, pkgs, ... }: with lib; {
  hm.services.dunst = {
    enable = true;

    settings = with config.theme; rec {
      global = {
        enable_recursive_icon_lookup = true;
        width = "(0, 1200)";
        height = 500;
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
        icon_position = "right";
        min_icon_size = 64;
        max_icon_size = global.height;
        dmenu = "rofi -dmenu -p dunst -no-fixed-num-lines";
        browser = "xdg-open";
        mouse_right_click = "context";
        show_indicators = false;
        icon_theme = config.hm.gtk.iconTheme.name;
        icon_path = mkForce "";
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

  nixpkgs.overlays = [ (self: super: {
    dunst = super.dunst.overrideAttrs (o: {
      version = "1.7.1";

      src = self.fetchFromGitHub {
        owner = "dunst-project";
        repo = "dunst";
        rev = "45c7c12280b9ab99a4ab2d3f659401e3c3288340";
        sha256 = "jAjuujQqsfn+QDPwAvcm0zqGlpnXHcBfgxjXp/iXXg0=";
      };

      patches = [];
    });
  }) ];
}
