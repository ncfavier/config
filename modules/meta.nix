# argument order: inputs, hardware, lib, here, config, modulesPath, utils, pkgs*
{ inputs, lib, here, config, utils, pkgs, ... }: with lib; {
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

  nixpkgs.overlays = [ (pkgs: prev: {
    config-cli = pkgs.writeShellScriptBin "config" ''
      configPath=${escapeShellArg utils.configPath}
      cmd=$1
      shift
      case $cmd in
        env) # meant to be sourced
          ${toBash config.lib.shellEnv}
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
          if (( $# )); then
            args=()
            for input do args+=(--update-input "$input"); done
            exec nix flake lock "$configPath" "''${args[@]}"
          else
            exec nix flake update "$configPath"
          fi;;

        repl|eval|bld)
          args=()
          for arg do case $arg in
            -w|--wip) args+=(--override-flake config "$configPath");;
            *) args+=("$arg")
          esac done
          set -- "''${args[@]}"
          ;;&
        repl)
          exec nix repl ~/.nix-defexpr "$@";;
        eval)
          exec nix eval -f ~/.nix-defexpr --json "$@" | jq -r .;;
        bld)
          (( $# )) || set -- config.system.build.toplevel
          exec nix build -f ~/.nix-defexpr --json "$@" | jq -r .;;

        specialise)
          name=$1
          shift
          exec sudo /run/current-system/specialisation/"$name"/bin/switch-to-configuration switch;;
        revert)
          exec sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch;;

        home)
          attr=nixosConfigurations.${escapeShellArg here.hostname}.config.hm.home.activationPackage
          export VERBOSE=1
          exec nix shell -v "$configPath#$attr" "$@" -c home-manager-generation;;
        @*)
          host=''${cmd#@}
          hostname=$(ssh -q "$host" 'echo "$HOSTNAME"')
          exec nixos-rebuild -v --flake "$configPath#$hostname" --target-host "$host" --use-remote-sudo "$@";;
        *)
          exec sudo nixos-rebuild -v --flake "$configPath" "$cmd" "$@";;
      esac
    '';
  }) ];

  hm.programs.bash.initExtra = ''
    _complete_nix_cmd() {
      local skip=$1; shift
      COMP_WORDS=("$@" "''${COMP_WORDS[@]:skip}")
      (( COMP_CWORD += $# - skip ))
      _completion_loader nix
      _complete_nix
    }
    _config() {
      local cur prev words cword
      local configPath=${escapeShellArg utils.configPath}
      _init_completion -n ':=&'
      if [[ $cword == 1 ]] || [[ $cword == 2 && $prev == @* ]]; then
        if [[ $cur == @* ]]; then
          _known_hosts_real -a -- "$cur"
        else
          compreply -W 'env compare update repl eval bld specialise revert home build build-vm test switch boot'
        fi
      else case ''${words[1]} in
        compare|update) _complete_nix_cmd $cword nix flake lock "$configPath" --update-input;;
        repl|eval|bld)  compreply -W '-w --wip';;&
        repl)           _complete_nix_cmd 2 nix repl ~/.nix-defexpr;;
        eval)           _complete_nix_cmd 2 nix eval -f ~/.nix-defexpr --json;;
        bld)            _complete_nix_cmd 2 nix build -f ~/.nix-defexpr --json;;
        home)           _complete_nix_cmd 2 nix shell "$configPath";;
      esac fi
    }
    complete -F _config config
  '';

  environment.systemPackages = with pkgs; [ config-cli ];
}
