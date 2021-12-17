{ lib, config, pkgs, ... }: with lib; {
  imports = attrValues (modulesIn ./.);

  nixpkgs.config.allowUnfree = true;

  programs.steam.enable = true;

  services.xserver.libinput.mouse.middleEmulation = false;

  hm = {
    home.packages = with pkgs; [
      legendary-gl
      teeworlds
      (writeShellScriptBin "zcatch" ''
        exec ${zcatch}/bin/zcatch_srv -f zcatch.cfg "$@"
      '')
      dwarf-fortress
    ];

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

  nix = {
    binaryCaches = mkAfter [ "https://nix-gaming.cachix.org" ];
    binaryCachePublicKeys = mkAfter [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
  };

  nixpkgs.overlays = [ (self: super: {
    zcatch = with self; stdenv.mkDerivation rec {
      pname = "zcatch";
      version = "0.3.5";
      src = fetchFromGitHub {
        owner = "jxsl13";
        repo = "zcatch";
        rev = "v${version}";
        sha256 = "XwoGf4Se3Yfxmi7uNzRrHp1VMkGIwWnRkWTjXlePsMM=";
        fetchSubmodules = true;
      };
      postPatch = ''
        substituteInPlace src/engine/shared/storage.cpp --replace /usr/share "$out/share"
      '';
      nativeBuildInputs = [ cmake ninja python3 ];
      cmakeFlags = [ "-GNinja" "-DCLIENT=OFF" ];
    };
  }) ];
  cachix.derivationsToPush = with pkgs; [
    zcatch
    dwarf-fortress
  ];
}
