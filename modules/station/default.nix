{ lib, here, pkgs, ... }: with lib; optionalAttrs here.isStation {
  imports = attrValues (importDir ./.);

  config = {
    boot.kernelParams = [ "mitigations=off" ];
    boot.kernel.sysctl."kernel.sysrq" = 1;

    programs.wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };

    environment.systemPackages = with pkgs; [
      gparted
    ];

    hm.home.packages = with pkgs; [
      chromium
      thunderbird
      github-desktop
      element-desktop
      tdesktop
      amfora
      libreoffice
      texlive.combined.scheme-full
      pandoc
      coq
      audacity
      gimp
      transmission-gtk
      qemu
      (writeShellScriptBin "power" ''
        actions=(shutdown reboot suspend "lock and suspend" logout)
        printf '%s\n' "''${actions[@]}" |
        case $(rofi -dmenu -p action -no-fixed-num-lines -theme-str 'window{width:200;}') in
            shutdown) sudo poweroff;;
            reboot) sudo reboot;;
            suspend) sudo systemctl suspend;;
            "lock and suspend") wm lock && sudo systemctl suspend;;
            logout) wm quit;;
        esac
      '')
      (shellScriptWithDeps "shoot" ./shoot.sh [
        slop imagemagick ffmpeg-full ffmpegthumbnailer
      ])
    ];

    my.extraGroups = [ "audio" "video" "wireshark" ];
  };
}
