{ lib, config, pkgs, ... }: with lib; {
  hm = {
    programs.feh = {
      enable = true;
      package = pkgs.feh.overrideAttrs (o: {
        patches = o.patches or [] ++ [
          (pkgs.fetchpatch {
            url = "https://github.com/derf/feh/pull/760/commits/e36811c53612d4c2a8a54f7b33e5701329f69ca4.patch";
            hash = "sha256-m63ysKDb1o/k2dA+W5ps9Hg/Y53UqoFcL9fMw4azRoI=";
          })
        ];
      });

      buttons = {
        prev_img = null;
        zoom_in = 4;
        next_img = null;
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
      feh -B ${config.theme.background} -g 1200x800 -Z -. --action9 ';bspc node -t ~fullscreen' --sort mtime --reverse
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
