# arguments order: inputs, hardware, lib, here, config, modulesPath, utils, pkgs*
{ inputs, lib, here, config, utils, pkgs, ... }: with lib; {
  # system.configurationRevision = inputs.self.rev or "dirty-${inputs.self.lastModifiedDate}"; # TODO

  _module.args.utils = {
    configPath = "${config.my.home}/git/config";
    mkMutableSymlink = path: config.hm.lib.file.mkOutOfStoreSymlink
      (utils.configPath + removePrefix (toString inputs.self) (toString path));
  };

  lib.shellEnv = {
    inherit (my) domain;
    server_hostname = my.server.hostname;
    inherit (here) isServer;
  };

  nixpkgs.overlays = [ (self: super: {
    shellScriptWithDeps = name: src: deps:
      self.writeScriptBin name ''
        #!${config.my.shellPath}
        ${optionalString (deps != []) ''
        PATH=${makeBinPath deps}''${PATH+:$PATH}
        ''}
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
    config-cli = self.writeShellScriptBin "config" ''
      configPath=${escapeShellArg utils.configPath}
      cmd=$1
      shift
      case $cmd in
          repl)
              exec nix repl ~/.nix-defexpr "$@"
              ;;
          compare)
              input=$1
              . <(nix flake metadata config --json | jq -r --arg input "$input" '
                def browse($url): @sh "xdg-open \($url)";
                .locks.nodes[$input] |
                if .locked.type == "github" then
                  browse("https://github.com/\(.locked.owner)/\(.locked.repo)/compare/\(.locked.rev)...\(.original.ref // "master")")
                elif .locked.type == "gitlab" then
                  browse("https://gitlab.com/\(.locked.owner)/\(.locked.repo)/-/compare/\(.locked.rev)...\(.original.ref // "master")")
                else
                  "echo unsupported input type"
                end
              ')
              ;;
          update)
              exec nix flake update "$configPath" "$@"
              ;;
          specialise)
              name=$1
              shift
              exec sudo /run/current-system/specialisation/"$name"/bin/switch-to-configuration switch "$@"
              ;;
          revert)
              exec sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch "$@"
              ;;
          home)
              attr=nixosConfigurations.${escapeShellArg here.hostname}.config.hm.home.activationPackage
              export VERBOSE=1
              exec nix shell -v "$configPath#$attr" "$@" -c home-manager-generation
              ;;
          eval)
              exec nix eval --json -f ~/.nix-defexpr "$@" | jq -r .
              ;;
          env) # meant to be sourced
              ${exportToBash config.lib.shellEnv}
              ;;
          @*) # TODO --no-gc-warning
              host=''${cmd#@}
              hostname=$(ssh -q "$host" 'echo "$HOSTNAME"')
              exec nixos-rebuild -v --flake "$configPath#$hostname" --target-host "$host" --use-remote-sudo "$@"
              ;;
          *)
              exec sudo nixos-rebuild -v --flake "$configPath" "$cmd" "$@"
              ;;
      esac
    '';
  }) ];

  environment.systemPackages = with pkgs; [ config-cli ];
}
