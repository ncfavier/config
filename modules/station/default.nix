{ lib, here, pkgs, ... }: with lib; optionalAttrs here.isStation {
  imports = attrValues (importDir ./.);

  config = {
    services.logind.killUserProcesses = true;

    environment.systemPackages = with pkgs; [
      gparted
    ];

    hm.home.packages = with pkgs; [
      chromium
      thunderbird
      libreoffice
      texlive.combined.scheme-full
      pandoc
      audacity
      gimp
      transmission-gtk
      qemu
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
