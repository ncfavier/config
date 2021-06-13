{ inputs, config, pkgs, lib, here, ... }: {
  system.configurationRevision = inputs.self.rev or "dirty-${inputs.self.lastModifiedDate}";

  lib.meta = rec {
    configPath = "${config.my.home}/git/config";
    mkMutableSymlink = path: config.hm.lib.file.mkOutOfStoreSymlink
      (configPath + lib.removePrefix (toString inputs.self) (toString path));
  };

  nixpkgs.overlays = [ (self: super: {
    shellScriptWithDeps = name: src: deps:
      self.writeScriptBin name ''
        #!${config.my.shellPath}
        PATH=${lib.makeBinPath deps}''${PATH:+:$PATH}
        ${builtins.readFile src}
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
      config=${lib.escapeShellArg config.lib.meta.configPath}
      case $1 in
          repl)
              shift
              exec nix repl ~/.nix-defexpr "$@";;
          update)
              shift
              if (( $# )); then
                  exec nix flake update "$config" "$@"
              else
                  exec "$0" switch --recreate-lock-file
              fi;;
          untest)
              exec sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch "$@";;
          home)
              attr=nixosConfigurations.${here.hostname}.config.hm.home.activationPackage
              exec nix shell "$config#$attr" -u DBUS_SESSION_BUS_ADDRESS -c home-manager-generation;;
          *)
              exec sudo nixos-rebuild --flake "$config" -v "$@";;
      esac
    '')
  ];
}
