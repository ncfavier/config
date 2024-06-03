{ lib, config, pkgs, ... }: with lib; {
  imports = attrValues (modulesIn ./.);

  nixpkgs.config.allowUnfree = true;

  programs.steam.enable = true;
  programs.gamemode.enable = true;

  services.libinput.mouse.middleEmulation = false;

  hm = {
    home.packages = with pkgs; [
      legendary-gl
      teeworlds
      ddnet
      # (writeShellScriptBin "zcatch" ''
      #   exec ${zcatch}/bin/zcatch_srv -f zcatch.cfg "$@"
      # '')
      (pkgs.dwarf-fortress.override {
        enableTruetype = false;
        settings.init.FONT = "Alloy_curses_12x12.png";
        extraPackages = [
          (pkgs.runCommandLocal "alloy-curses" { } ''
            mkdir -p "$out/data/art"
            ln -s ${pkgs.fetchurl {
              url = "https://dwarffortresswiki.org/images/0/03/Alloy_curses_12x12.png";
              hash = "sha256-r+ossYw3BF5rp+Da1Mle0kBKFsA0/IHGD3ENe3JAyHk=";
            }} "$out/data/art/Alloy_curses_12x12.png"
          '')
        ];
      })
    ];

    xdg.dataFile."ddnet".source =
      config.hm.lib.file.mkOutOfStoreSymlink "${config.hm.xdg.dataHome}/teeworlds";

    xdg.dataFile."teeworlds/zcatch.cfg".text = ''
      sv_register 0
      sv_port 8303
      sv_db_type ""
      sv_map ctf5
      exec maps/maps.cfg
      sv_weapon_mode 3
      sv_inactivekick_time 0
    '';

    xdg.dataFile."df_linux/data/save".source =
      config.hm.lib.file.mkOutOfStoreSymlink "${config.synced.saves.path}/df";
  };

  nixpkgs.overlays = [ (pkgs: prev: {
    zcatch = with pkgs; stdenv.mkDerivation {
      pname = "zcatch";
      version = "0.3.5";
      src = fetchFromGitHub {
        owner = "jxsl13";
        repo = "zcatch";
        rev = "e6e87a7fd84f24ef9306c39275ad7003965e55dd";
        sha256 = "sha256-3rFHUWyjGRHgVld8uj7BAaTndpAGWgSMwXUfhNsfbgY=";
        fetchSubmodules = true;
      };
      postPatch = ''
        substituteInPlace src/engine/shared/storage.cpp --replace /usr/share "$out/share"
      '';
      nativeBuildInputs = [ cmake ninja python3 ];
      cmakeFlags = [ "-GNinja" "-DCLIENT=OFF" ];
    };
  }) ];
}
