{ lib, this, config, pkgs, ... }: with lib; {
  options.cachix.derivationsToPush = mkOption {
    description = "A list of derivations to push to cachix.";
    type = with types; listOf package;
    default = [];
  };

  config = {
    secrets.cachix = {
      owner = my.username;
      inherit (config.my) group;
    };

    hm.xdg.configFile."cachix/cachix.dhall" = mkIf (this ? hostname) { # temporary hack to detect if this is the ISO config
      source = config.hm.lib.file.mkOutOfStoreSymlink config.secrets.cachix.path;
    };

    system.extraSystemBuilderCmds = ''
      {
        printf '%s\n' ${escapeShellArgs config.cachix.derivationsToPush}
        grep -oE '\S*-man-cache' "$out/etc/man_db.conf" 2> /dev/null || true
      } > "$out/derivations-to-push"
    '';
    environment.systemPackages = with pkgs; [
      cachix
      (writeShellScriptBin "cachix-push" ''
        exec cachix push ${my.githubUsername} "$@" < /run/current-system/derivations-to-push
      '')
    ];

    nix.settings = {
      substituters = mkOrder 1200 [
        "https://${my.githubUsername}.cachix.org"
        "https://nix-community.cachix.org"
        "https://nixos-search.cachix.org"
      ];

      trusted-public-keys = mkOrder 1200 [
        "${my.githubUsername}.cachix.org-1:RpBMt+EIZOwVwU1CW71cWZAVJ9DCNbCMsX8VOGSf3ME="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixos-search.cachix.org-1:1HV3YF8az4fywnH+pAd+CXFEdpTXtv9WpoivPi+H70o="
      ];
    };
  };
}
