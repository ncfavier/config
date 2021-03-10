{ inputs, config, pkgs, lib, ... }: {
  system.configurationRevision = inputs.self.rev or "dirty-${inputs.self.lastModifiedDate}";

  lib.meta = rec {
    mutableConfig = "${config.my.home}/git/config";
    mkMutableSymlink = path: config.myHm.lib.file.mkOutOfStoreSymlink
      (mutableConfig + lib.removePrefix (toString inputs.self) (toString path));
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "config" ''
      case $1 in
        repl)
          shift
          exec nix repl ~/.nix-defexpr "$@";;
        update)
          shift
          (( $# )) || set -- --recreate-lock-file
          exec nix flake update ${lib.escapeShellArg config.lib.meta.mutableConfig} "$@";;
        *) exec sudo nixos-rebuild --flake ${lib.escapeShellArg config.lib.meta.mutableConfig} -v "$@";;
      esac
    '')
  ];
}
