{ lib, this, pkgs, ... }: with lib; optionalAttrs this.isStation {
  imports = attrValues (modulesIn ./.);

  config = {
    boot.kernelParams = [ "mitigations=off" ];
    boot.kernel.sysctl."kernel.sysrq" = 1;

    environment.etc."systemd/system-sleep/batenergy".source = pkgs.writeShellScript "batenergy" ''
      PATH=${makeBinPath [ pkgs.coreutils pkgs.bc ]}
      source ${pkgs.fetchFromGitHub {
        owner = "equaeghe";
        repo = "batenergy";
        rev = "13c381f68f198af361c5bd682b32577131fbb60f";
        hash = "sha256-4JQrSD8HuBDPbBGy2b/uzDvrBUZ8+L9lAnK95rLqASk=";
      }}/batenergy.sh "$@"
    '';

    programs.adb.enable = true;

    programs.wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };

    my.extraGroups = [ "audio" "video" "wireshark" "adbusers" ];

    environment.systemPackages = with pkgs; [
      gparted
      gnome-system-monitor
      gnome-disk-utility
    ];

    hm.home.packages = with pkgs; [
      chromium
      thunderbird
      discord
      tdesktop
      signal-desktop
      libreoffice-fresh
      xournalpp
      pandoc
      coq
      (agda.withPackages (p: with p; [
        standard-library
        cubical
        agda-categories
      ]))
      audacity
      gimp
      inkscape
      poppler_utils
      transmission_4-gtk
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
        deps = [ slop imagemagick ffmpeg-full ffmpegthumbnailer ];
      })
      tmsu
    ];

    hm.programs.texlive = {
      enable = true;
      extraPackages = tpkgs: {
        inherit (tpkgs)
          scheme-medium
          collection-latexextra
          collection-fontsextra
          collection-bibtexextra
          ;
      };
    };

    hm.xdg.configFile."agda/defaults".text = ''
      standard-library
      cubical
      agda-categories
    '';

    cachix.derivationsToPush = [ pkgs.tmsu ];
  };
}
