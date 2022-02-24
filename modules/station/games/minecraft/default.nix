{ config, pkgs, ... }: let
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
        url = "https://github.com/CaffeineMC/sodium-fabric/releases/download/mc1.17.1-0.3.3/sodium-fabric-mc1.17.1-0.3.3+build.8.jar";
        sha256 = "1c78nwvs3fv41w9v405sz7vp33vby40slaynd2cn7xrqn1zsh6xr";
      })
      (pkgs.fetchurl {
        url = "https://github.com/CaffeineMC/lithium-fabric/releases/download/mc1.17.1-0.7.5/lithium-fabric-mc1.17.1-0.7.5.jar";
        sha256 = "041j50vccb5yk3957g1nl7vk701rbq3ggsid3mm91sbfkm1ys00w";
      })
      (pkgs.fetchurl {
        url = "https://github.com/CaffeineMC/phosphor-fabric/releases/download/mc1.17.x-0.8.0/phosphor-fabric-mc1.17.x-0.8.0.jar";
        sha256 = "1klcacydjh0j16ibsjbzdqxa1in87mrspiz8yc52p5bvihc3yaxr";
      })
    ];
    home.file.".minecraft/options.txt".source =
      config.lib.meta.mkMutableSymlink ./options.txt;
    home.file.".minecraft/config/sodium-options.json" = {
      source = config.lib.meta.mkMutableSymlink ./sodium.json;
      force = true;
    };
  };
}
