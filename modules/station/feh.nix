{ lib, pkgs, ... }: with lib; {
  config.hm = {
    programs.feh = {
      enable = true;

      buttons = {
        prev_img = null;
        next_img = null;
        pan = 1;
        zoom_in = 4;
        zoom_out = 5;
      };

      keybindings = {
        save_filelist = null;
        toggle_fullscreen = null;
        action_9 = "f";
        action_0 = null;
        render = "Return";
        orient_1 = null;
        orient_3 = null;
        prev_img = [ "Left" "less" ];
        next_img = [ "Right" "greater" "space" ];
        close = [ "Escape" "BackSpace" ];
        quit = "q";
      };
    };

    xdg.configFile."feh/themes".text = ''
      feh -B ${theme.background} -g 800x500 -. --action9 ';bspc node -t ~fullscreen'
    '';

    home.packages = with pkgs; [
      (writeShellScriptBin "random-wallpaper" ''
        pictures=$(xdg-user-dir PICTURES)
        wallpaper=$(find "$pictures/horizontal" "$pictures/tileable" -type f | shuf -n 1)
        case $wallpaper in
            $pictures/horizontal/*)
                mode=fill;;
            $pictures/tileable/*)
                mode=tile;;
        esac
        feh --bg-"$mode" "$wallpaper"
      '')
    ];
  };
}
