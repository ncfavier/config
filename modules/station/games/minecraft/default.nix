{ config, pkgs, utils, ... }: let
  version = "1.17.1";
in {
  hm = {
    home.packages = with pkgs; [
      minecraft
      (writeShellScriptBin "minecraft-install-fabric" ''
        ${fabric-installer}/bin/fabric-installer client -mcversion ${version} "$@"
        # hide the "player safety disclaimer"
        profile=$(jq -r '.profiles."fabric-loader-${version}" | "\(.lastVersionId)_\(.name)"' ~/.minecraft/launcher_profiles.json)
        state=$(jq --arg profile "$profile" \
          '.data.UiEvents |= (fromjson | (.hidePlayerSafetyDisclaimer[$profile] = true) | tojson)' ~/.minecraft/launcher_ui_state.json) &&
        printf '%s\n' "$state" > ~/.minecraft/launcher_ui_state.json
      '')
    ];

    home.file.".minecraft/saves".source =
      config.hm.lib.file.mkOutOfStoreSymlink "${config.synced.saves.path}/minecraft";
    home.file.".minecraft/mods".source = pkgs.linkFarmFromDrvs "minecraft-mods" [
      (pkgs.fetchurl {
        url = "https://github.com/CaffeineMC/sodium-fabric/releases/download/mc1.17.1-0.3.2/sodium-fabric-mc1.17.1-0.3.2+build.7.jar";
        sha256 = "08hh7fhw2zd7ak4cwg6mysgxabgjxhxh2q0w35mbawngz7890ip2";
      })
      (pkgs.fetchurl {
        url = "https://github.com/CaffeineMC/lithium-fabric/releases/download/mc1.17.1-0.7.5/lithium-fabric-mc1.17.1-0.7.5.jar";
        sha256 = "041j50vccb5yk3957g1nl7vk701rbq3ggsid3mm91sbfkm1ys00w";
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
