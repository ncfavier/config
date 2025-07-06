{ lib, this, pkgs, ... }: with lib; optionalAttrs this.isStation {
  imports = attrValues (modulesIn ./.);

  config = {
    boot.kernelParams = [ "mitigations=off" ];
    boot.kernel.sysctl."kernel.sysrq" = 1;

    environment.etc."systemd/system-sleep/batenergy".source = pkgs.writeShellScript "batenergy" ''
      PATH=${makeBinPath [ pkgs.coreutils pkgs.bc ]}
      source ${pkgs.fetchFromGitHub {
        owner = my.githubUsername;
        repo = "batenergy";
        rev = "6109882f05c0762d82fa013dd76d8425aacd58fb";
        hash = "sha256-JS/NAO8NhAy+3XmI+rNYRN/H0q50Zv+AETmfvmK03eE=";
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
      discord
      tdesktop
      signal-desktop
      libreoffice-fresh
      xournalpp
      zotero
      pandoc
      inlyne
      typos
      (agda.withPackages (p: with p; [
        standard-library
        cubical
      ]))
      coq
      elan
      ocamlPackages.cooltt
      audacity
      gimp
      evince
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
      gucharmap
      (shellScriptWith "unicode-analyse" ./unicode-analyse.sh {
        deps = [ zenity gucharmap ];
      })
    ];

    hm.programs.texlive = {
      enable = true;
      packageSet = (pkgs.pr 413558 "sha256-aDCoPtyLPjxDyiZF5kfkaEkhH/xP4P/uTQ+tX9lX/2s=").texlive; # TODO
      extraPackages = tpkgs: {
        inherit (tpkgs)
          scheme-medium
          collection-latexextra
          collection-fontsextra
          collection-bibtexextra
          collection-langcjk
          collection-publishers
          ;
      };
    };

    hm.xdg.configFile."agda/defaults".text = ''
      standard-library
      cubical
    '';

    cachix.derivationsToPush = [ pkgs.tmsu ];
  };
}
