{ config, pkgs, ... }: let
  zcatch = with pkgs; stdenv.mkDerivation rec {
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
  programs.steam.enable = true;

  hm = {
    home.packages = with pkgs; [
      teeworlds
      dwarf-fortress
      minecraft
      (writeShellScriptBin "minecraft-install-fabric" ''
        exec ${fabric-installer}/bin/fabric-installer client -mcversion 1.16.5 "$@"
      '')
      (writeShellScriptBin "zcatch" ''
        exec ${zcatch}/bin/zcatch_srv -f zcatch.cfg "$@"
      '')
    ];

    xdg.dataFile."df_linux/data/save".source =
      config.hm.lib.file.mkOutOfStoreSymlink "${config.synced.saves.path}/df";

    home.file.".minecraft/saves".source =
      config.hm.lib.file.mkOutOfStoreSymlink "${config.synced.saves.path}/minecraft";
    home.file.".minecraft/mods".source =
      pkgs.linkFarmFromDrvs "minecraft-mods" [
        (pkgs.fetchurl {
          url = "https://media.forgecdn.net/files/3067/101/sodium-fabric-mc1.16.3-0.1.0.jar";
          sha256 = "1gaz80y2jc3gkvhvsp7il6lrf64bz9gfnim6243figd34f15xi14";
        })
        (pkgs.fetchurl {
          url = "https://edge.forgecdn.net/files/3344/974/lithium-fabric-mc1.16.5-0.6.6.jar";
          sha256 = "0a2dp8dx6sk6zwapizpvm7jk07gh1q1sv1gzdgbj6c7w15av8rwh";
        })
        (pkgs.fetchurl {
          url = "https://edge.forgecdn.net/files/3294/303/phosphor-fabric-mc1.16.3-0.7.2+build.12.jar";
          sha256 = "142ka4p135ml29gx7i44dlfb8f4c6m8izbswph5v839kp82wcpnn";
        })
      ];

    xdg.dataFile."teeworlds/zcatch.cfg".source = zcatchConfig;
  };
}
