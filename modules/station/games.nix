{ config, syncedFolders, pkgs, ... }: let
  zcatch = with pkgs; stdenv.mkDerivation rec {
    pname = "zcatch";
    version = "0.3.5";
    src = fetchFromGitHub {
      owner = "jxsl13";
      repo = "zcatch";
      rev = "v${version}";
      sha256 = "sha256-XwoGf4Se3Yfxmi7uNzRrHp1VMkGIwWnRkWTjXlePsMM=";
      fetchSubmodules = true;
    };
    postPatch = ''
      substituteInPlace src/engine/shared/storage.cpp --replace /usr/share "$out/share"
    '';
    nativeBuildInputs = [ cmake ninja python3 ];
    cmakeFlags = [ "-GNinja" "-DCLIENT=OFF" ];
  };
  zcatchConfig = builtins.toFile "zcatch.cfg" ''
    sv_register 0
    sv_port 8303
    sv_db_type ""
    sv_map ctf5
    exec maps/maps.cfg
    sv_weapon_mode 3
    sv_inactivekick_time 0
  '';
in {
  hm = {
    home.packages = with pkgs; [
      teeworlds
      dwarf-fortress
      minecraft
      (writeShellScriptBin "zcatch" ''
        exec ${zcatch}/bin/zcatch_srv -f zcatch.cfg
      '')
    ];

    xdg.dataFile."df_linux/data/save".source = config.hm.lib.file.mkOutOfStoreSymlink "${syncedFolders.saves.path}/df";
    xdg.dataFile."teeworlds/zcatch.cfg".source = zcatchConfig;
  };
}
