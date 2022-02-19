{ lib, here, utils, pkgs, ... }: with lib; optionalAttrs here.isStation {
  imports = attrValues (modulesIn ./.);

  config = {
    boot.kernelParams = [ "mitigations=off" ];
    boot.kernel.sysctl."kernel.sysrq" = 1;

    services.earlyoom = {
      enable = true;
      freeMemThreshold = 5;
      freeSwapThreshold = 5;
    };

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
      (texlive.combine {
        inherit (texlive)
          scheme-medium
          collection-latexextra
          collection-fontsextra
          collection-bibtexextra;
      })
      pandoc
      coq_8_14
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
      (utils.shellScriptWith "shoot" ./shoot.sh {
        deps = [
          slop imagemagick ffmpeg-full ffmpegthumbnailer
        ];
      })
    ];

    my.extraGroups = [ "audio" "video" "wireshark" ];
  };
}
