{ config, pkgs, lib, here, ... }: lib.optionalAttrs here.isStation {
  imports = builtins.attrValues (lib.importDir ./.);

  config = {
    environment.systemPackages = with pkgs; [
      gparted
    ];

    myHm.home.packages = with pkgs; [
      texlive.combined.scheme-full
      thunderbird
      audacity
      transmission-gtk
      (writeShellScriptBin "power" ''
        printf '%s\n' shutdown reboot suspend logout |
        case $(rofi -dmenu -p action -lines 4 -width 200) in
            shutdown) sudo poweroff;;
            reboot) sudo reboot;;
            suspend) sudo systemctl suspend;;
            logout) wm quit;;
        esac
      '')
      (shellScriptWithDeps "shoot" ./shoot.sh [
        slop imagemagick ffmpeg-full ffmpegthumbnailer
      ])
    ];
  };
}
