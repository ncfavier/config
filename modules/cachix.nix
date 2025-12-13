{ lib, config, pkgs, ... }: with lib; {
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

    hm.xdg.configFile."cachix/cachix.dhall".source = config.hm.lib.file.mkOutOfStoreSymlink config.secrets.cachix.path;

    system.systemBuilderCommands = ''
      {
        printf '%s\n' ${escapeShellArgs (concatMap getAllOutputs config.cachix.derivationsToPush)}
        grep -oE '\S*-man-cache' "$out/etc/man_db.conf" 2> /dev/null || true
      } > "$out/derivations-to-push"
    '';
    environment.systemPackages = with pkgs; [
      cachix
      (writeShellScriptBin "cachix-push" ''
        exec cachix push ${my.githubUsername} "$@" < /run/current-system/derivations-to-push
      '')
    ];
  };
}
