# arguments order: { inputs, hardware, lib, here, config, modulesPath, secrets, syncedFolders, utils, pkgsWip, pkgs, pkgsStable }
{ inputs, lib, here, config, utils, pkgs, ... }: with lib; {
  system.configurationRevision = inputs.self.rev or "dirty-${inputs.self.lastModifiedDate}";

  _module.args.utils = rec {
    configPath = "${config.my.home}/git/config";
    mkMutableSymlink = path: config.hm.lib.file.mkOutOfStoreSymlink
      (configPath + removePrefix (toString inputs.self) (toString path));
  };

  lib.shellEnv = {
    inherit (my) domain;
    server_hostname = my.server.hostname;
    inherit (here) isServer;
    inherit (lib) theme;
  };

  nixpkgs.overlays = [ (self: super: {
    shellScriptWithDeps = name: src: deps:
      self.writeScriptBin name ''
        #!${config.my.shellPath}
        PATH=${makeBinPath deps}''${PATH:+:$PATH}
        ${readFile src}
      '';
    python3ScriptWithDeps = name: src: deps:
      self.stdenv.mkDerivation {
        inherit name;
        buildInputs = [ (self.python3.withPackages deps) ];
        dontUnpack = true;
        installPhase = ''
          install -D -m555 ${src} "$out/bin/${name}"
        '';
      };
  }) ];

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "config" ''
      configPath=${escapeShellArg utils.configPath}
      cmd=$1
      shift
      case $cmd in
          repl)
              exec nix repl ~/.nix-defexpr "$@";;
          update)
              if (( $# )); then
                  exec nix flake update "$configPath" "$@"
              else
                  exec "$0" switch --recreate-lock-file
              fi;;
          untest)
              exec sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch "$@";;
          home)
              attr=nixosConfigurations.${escapeShellArg here.hostname}.config.hm.home.activationPackage
              exec nix shell "$configPath#$attr" -u DBUS_SESSION_BUS_ADDRESS "$@" -c home-manager-generation;;
          env) # meant to be sourced
              ${exportToShell config.lib.shellEnv}
              ;;
          *)
              exec sudo nixos-rebuild --flake "$configPath" -v "$cmd" "$@";;
      esac
    '')
  ];
}
