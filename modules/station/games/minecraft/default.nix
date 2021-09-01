{ config, pkgs, utils, ... }: {
  hm = {
    home.packages = with pkgs; [
      minecraft
      (writeShellScriptBin "minecraft-install-fabric" ''
        exec ${fabric-installer}/bin/fabric-installer client -mcversion 1.17.1 "$@"
      '')
    ];

    home.file.".minecraft/saves".source =
      config.hm.lib.file.mkOutOfStoreSymlink "${config.synced.saves.path}/minecraft";
    home.file.".minecraft/mods".source = pkgs.linkFarmFromDrvs "minecraft-mods" [
      (pkgs.fetchurl {
        url = "https://github.com/CaffeineMC/sodium-fabric/releases/download/mc1.17.1-0.3.1/sodium-fabric-mc1.17.1-0.3.1+build.6.jar";
        sha256 = "1smsizqsjdfv1w35i7bvccxi2i9hnsybjrhfb8yzsv630zd8p8lr";
      })
      (pkgs.fetchurl {
        url = "https://github.com/CaffeineMC/lithium-fabric/releases/download/mc1.17.1-0.7.4/lithium-fabric-mc1.17.1-0.7.4.jar";
        sha256 = "0wwfylr00vz6idwfr1f3k2739rgrvfpb7slkn6ss0sixjb9r85ff";
      })
      # (pkgs.fetchurl {
      #   url = "https://github.com/CaffeineMC/phosphor-fabric/releases/download/mc1.16.2-v0.7.2/phosphor-fabric-mc1.16.3-0.7.2+build.12.jar";
      #   sha256 = "142ka4p135ml29gx7i44dlfb8f4c6m8izbswph5v839kp82wcpnn";
      # })
    ];
    home.file.".minecraft/options.txt".source =
      utils.mkMutableSymlink ./options.txt;
    home.file.".minecraft/config/sodium-options.json" = {
      source = utils.mkMutableSymlink ./sodium.json;
      force = true;
    };
  };
}
