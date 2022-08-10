{ config, pkgs, ... }: let
  # TODO switch to PolyMC or fix the minecraft-launcher package https://github.com/NixOS/nixpkgs/issues/179323#
  # version = "1.19.2";
  version = "1.18.2";
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
      # (pkgs.fetchurl {
      #   url = "https://github.com/CaffeineMC/sodium-fabric/releases/download/mc1.19-0.4.2/sodium-fabric-mc1.19-0.4.2+build.16.jar";
      #   sha256 = "sha256-O9Xk/HWbijEdwIhQLq6rxJZ25MCxDTgJdWNcRscfA30=";
      # })
      # (pkgs.fetchurl {
      #   url = "https://github.com/CaffeineMC/lithium-fabric/releases/download/mc1.19.2-0.8.3/lithium-fabric-mc1.19.2-0.8.3.jar";
      #   sha256 = "sha256-87nUmGLqVtWp69Fct4dcE34IWEqVT2RP6oar4sldgG8=";
      # })
      # (pkgs.fetchurl {
      #   url = "https://github.com/CaffeineMC/phosphor-fabric/releases/download/mc1.19.x-0.8.1/phosphor-fabric-mc1.19.x-0.8.1.jar";
      #   sha256 = "sha256-LRuOvSFtXAQ1bAvKU4mbk9PWArsathFFGwsPlxrB8ds=";
      # })
      (pkgs.fetchurl {
        url = "https://github.com/CaffeineMC/sodium-fabric/releases/download/mc1.18.2-0.4.1/sodium-fabric-mc1.18.2-0.4.1+build.15.jar";
        sha256 = "sha256-d2+zzYyN3uiY6x2dyIpy2JmqqHkvIZFLOa2ZDOolN4Q=";
      })
      (pkgs.fetchurl {
        url = "https://github.com/CaffeineMC/lithium-fabric/releases/download/mc1.18.2-0.7.9/lithium-fabric-mc1.18.2-0.7.9.jar";
        sha256 = "sha256-GdV7g/3YhZOiGSEabmk2vY3ZCVf9GeVoH/qFb+Nlv1g=";
      })
      (pkgs.fetchurl {
        url = "https://github.com/CaffeineMC/phosphor-fabric/releases/download/mc1.18.x-0.8.1/phosphor-fabric-mc1.18.x-0.8.1.jar";
        sha256 = "sha256-QqE532MANA8jzaRFf8C6fjkSTBusBdiSMrAWe9UeanU=";
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
