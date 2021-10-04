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
      path = "${config.hm.xdg.configHome}/cachix/cachix.dhall";
    };

    environment.systemPackages = with pkgs; [
      cachix
      (writeShellScriptBin "cachix-push" ''
        exec cachix push ${my.githubUsername} ${escapeShellArgs config.cachix.derivationsToPush} "$@"
      '')
    ];

    nix = {
      binaryCaches = [
        "https://nix-community.cachix.org"
        "https://ncfavier.cachix.org"
        "https://mic92.cachix.org" # for sops-nix
      ];

      binaryCachePublicKeys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "ncfavier.cachix.org-1:RpBMt+EIZOwVwU1CW71cWZAVJ9DCNbCMsX8VOGSf3ME="
        "mic92.cachix.org-1:gi8IhgiT3CYZnJsaW7fxznzTkMUOn1RY4GmXdT/nXYQ="
      ];
    };
  };
}
