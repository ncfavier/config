{ lib, config, ... }: with lib; {
  hm.programs.imv = {
    enable = true;
    settings = {
      options = {
        background = removePrefix "#" config.theme.background;
        overlay_font = "monospace:18";
        title_text = "imv - [$imv_current_index/$imv_file_count] $imv_current_file";
      };
      binds = {
        i = "overlay";
        "<Escape>" = "quit";
        "<Shift+period>" = "next_frame";
        "<less>" = "prev";
        "<Shift+greater>" = "next";
        "<space>" = "next";
        "p" = "toggle_playing";
      };
    };
  };
}
