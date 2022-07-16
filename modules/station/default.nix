{ lib, this, pkgs, ... }: with lib; optionalAttrs this.isStation {
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
      discord
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
      (agda.withPackages (p: with p; [
        standard-library
        cubical
      ]))
      racket
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
      (shellScriptWith "shoot" ./shoot.sh {
        deps = [
          slop imagemagick ffmpeg-full ffmpegthumbnailer
        ];
      })
    ];

    hm.home.file.".agda/defaults".text = ''
      standard-library
      cubical
    '';

    my.extraGroups = [ "audio" "video" "wireshark" ];
  };
}
