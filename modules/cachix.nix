{ lib, config, pkgs, ... }: with lib; {
  options.cachix.derivationsToPush = mkOption {
    description = "A list of derivations to push to cachix.";
    type = with types; listOf path;
    default = [];
  };

  config = {
    secrets.cachix = {
      owner = my.username;
      inherit (config.my) group;
    };

    hm.xdg.configFile."cachix/cachix.dhall".source = config.hm.lib.file.mkOutOfStoreSymlink config.secrets.cachix.path;

    environment.systemPackages = with pkgs; [
      cachix
      (writeShellScriptBin "cachix-push" ''
        exec cachix push ${my.githubUsername} ${escapeShellArgs config.cachix.derivationsToPush} "$@"
      '')
    ];

    nix.settings = {
      substituters = mkOrder 1200 [
        "https://nix-community.cachix.org"
        "https://${my.githubUsername}.cachix.org"
      ];

      trusted-public-keys = mkOrder 1200 [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "${my.githubUsername}.cachix.org-1:RpBMt+EIZOwVwU1CW71cWZAVJ9DCNbCMsX8VOGSf3ME="
      ];
    };
  };
}
