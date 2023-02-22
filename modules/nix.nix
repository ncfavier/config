{ inputs, lib, this, config, pkgs, pkgsRev, ... }: with lib; {
  config = {
    system.extraDependencies = concatMap collectFlakeInputs (with inputs; [
      nixpkgs nixpkgs-stable nixos-hardware nur
    ]);

    _module.args = let
      importNixpkgs = nixpkgs: import nixpkgs {
        inherit (config.nixpkgs) localSystem crossSystem config;
      };
    in {
      pkgsStable = importNixpkgs inputs.nixpkgs-stable;
      pkgsRev = rev: sha256: importNixpkgs (pkgs.fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs";
        inherit rev sha256;
      });
      pkgsPR = pr: pkgsRev "refs/pull/${toString pr}/head";
      pkgsMine = rev: sha256: importNixpkgs (pkgs.fetchFromGitHub {
        owner = my.githubUsername;
        repo = "nixpkgs";
        inherit rev sha256;
      });
      pkgsLocal = importNixpkgs "${config.my.home}/git/nixpkgs"; # only available in --impure mode
    };

    lib.meta = {
      configPath = "${config.my.home}/git/config";
      mkMutableSymlink = path: config.hm.lib.file.mkOutOfStoreSymlink
        (config.lib.meta.configPath + removePrefix (toString inputs.self) (toString path));
    };

    secrets.nix-access-tokens = {
      mode = "0440";
      group = config.users.groups.keys.name;
    };

    nix = {
      settings = {
        experimental-features = [ "nix-command" "flakes" "ca-derivations" "auto-allocate-uids" ];
        warn-dirty = false;
        keep-derivations = true;
        trusted-users = [ "root" "@wheel" ];
        auto-allocate-uids = true;
        max-jobs = "auto";
        log-lines = 30;
        connect-timeout = 5;
      };

      extraOptions = ''
        !include ${config.secrets.nix-access-tokens.path}
      '';

      registry = {
        config.flake = inputs.self;
        config-git = {
          exact = false;
          to = {
            type = "git";
            url = "file:${config.lib.meta.configPath}";
          };
        };
        config-github = {
          exact = false;
          to = {
            type = "github";
            owner = my.githubUsername;
            repo = "config";
          };
        };
      };

      nixPath = [ "nixpkgs=/etc/nixpkgs" ];

      gc = {
        automatic = true;
        options = "--delete-older-than 30d";
      };
      optimise.automatic = true;
    };

    systemd.user.services.nix-index = {
      description = "Update the nix-index database";
      path = [ pkgs.curl ];
      script = ''
        db=''${XDG_CACHE_HOME:-~/.cache}/nix-index/files
        mkdir -p "''${db%/*}"
        curl -fsSLR -o "$db" -z "$db" --retry 100 \
          https://github.com/Mic92/nix-index-database/releases/latest/download/index-${config.nixpkgs.system}
      '';
      startAt = "Sun 04:15";
    };
    hm.xdg.configFile."systemd/user/timers.target.wants/nix-index.timer".source =
      config.hm.lib.file.mkOutOfStoreSymlink "/etc/systemd/user/nix-index.timer";

    environment.etc.nixpkgs.source = inputs.nixpkgs;

    environment.variables.NIX_SHELL_PRESERVE_PROMPT = "1";

    environment.systemPackages = with pkgs; [
      config-cli
      nix-bash-completions
      nix-index-unwrapped # use the system-wide nix
      nix-prefetch-git
      nix-prefetch-github
      nix-diff
      nix-top
      nix-output-monitor
      nix-tree
      nixpkgs-fmt
      nixpkgs-review
      nixfmt
      nil
    ];

    lib.shellEnv = {
      inherit (my) domain;
      server_hostname = my.server.hostname;
      inherit (this) isServer;
    };

    nixpkgs.overlays = [
      inputs.nur.overlay
      (pkgs: prev: {
        config-cli = hiPrio (pkgs.writeShellScriptBin "config" ''
          configPath=${escapeShellArg config.lib.meta.configPath}
          cmd=$1
          shift
          case $cmd in
            repl|eval|bld|rev)
              args=() flakeArgs=()
              for arg do case $arg in
                -w|--wip) flakeArgs+=(--override-flake config "$configPath");;
                *) args+=("$arg")
              esac done
              set -- "''${args[@]}"
              ;;&

            env) # meant to be sourced
              ${toShellVars config.lib.shellEnv}
              ;;

            compare)
              input=$1
              . <(nix flake metadata --json config | jq -r --arg input "$input" '
                def browse($url): @sh "xdg-open \($url)";
                .locks.nodes[$input] |
                if .locked.type == "github" then
                  browse("https://github.com/\(.locked.owner)/\(.locked.repo)/compare/\(.locked.rev)...\(.original.ref // "master")")
                elif .locked.type == "gitlab" then
                  browse("https://gitlab.com/\(.locked.owner)/\(.locked.repo)/-/compare/\(.locked.rev)...\(.original.ref // "master")")
                else
                  "echo unsupported input type \(.locked.type) (supported: github, gitlab)"
                end
              ')
              ;;
            update)
              if (( $# )); then
                args=()
                for input do args+=(--update-input "$input"); done
                exec nix flake lock --refresh "''${args[@]}" "$configPath"
              else
                # https://github.com/NixOS/nix/issues/6095 prevents using config-git here
                exec nix flake update -v --refresh "$configPath"
              fi
              ;;
            rev)
              if (( $# )); then
                expr=inputs.''${1//'/'/.inputs.}.rev
              else
                expr=self.revision
              fi
              nix eval "''${flakeArgs[@]}" -f ~/.nix-defexpr --raw "$expr"
              echo
              ;;

            repl)
              exec nix repl "''${flakeArgs[@]}" -f ~/.nix-defexpr "$@";;
            eval)
              exec nix eval "''${flakeArgs[@]}" -f ~/.nix-defexpr --json "$@" | jq -r .;;
            bld)
              # https://github.com/NixOS/nix/issues/6661
              exec nix-build "''${flakeArgs[@]}" ~/.nix-defexpr -A "$@";;

            specialise)
              name=$1
              shift
              exec sudo /run/current-system/specialisation/"$name"/bin/switch-to-configuration switch;;
            revert)
              exec sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch;;

            home)
              attr=nixosConfigurations.${escapeShellArg this.hostname}.config.hm.home.activationPackage
              export VERBOSE=1
              exec nix shell -v "$configPath#$attr" "$@" -c home-manager-generation;;
            @*)
              host=''${cmd#@}
              hostname=$(ssh -q "$host" 'echo "$HOSTNAME"')
              exec nixos-rebuild -v --flake "$configPath#$hostname" --target-host "$host" --use-remote-sudo "$@";;
            *)
              exec nixos-rebuild -v --fast --flake "$configPath" --use-remote-sudo "$cmd" "$@";;
          esac
        '');
      })
    ];

    hm = {
      programs.bash.initExtra = ''
        _complete_nix_cmd() {
          local skip=$1; shift
          COMP_WORDS=("$@" "''${COMP_WORDS[@]:skip}")
          (( COMP_CWORD += $# - skip ))
          _completion_loader nix
          _complete_nix
        }
        _config() {
          local cur prev words cword
          local configPath=${escapeShellArg config.lib.meta.configPath}
          _init_completion -n ':=&'
          if [[ $cword == 1 ]] || [[ $cword == 2 && $prev == @* ]]; then
            if [[ $cur == @* ]]; then
              _known_hosts_real -a -- "$cur"
            else
              compreply -W 'env compare update repl eval bld specialise revert home build build-vm test switch boot'
            fi
          else case ''${words[1]} in
            compare|update|rev) _complete_nix_cmd $cword nix flake lock "$configPath" --update-input;;
            repl|eval|bld)      compreply -W '-w --wip';;&
            repl)               _complete_nix_cmd 2 nix repl ~/.nix-defexpr;;
            eval)               _complete_nix_cmd 2 nix eval -f ~/.nix-defexpr --json;;
            bld)                _complete_nix_cmd 2 nix build -f ~/.nix-defexpr --json;;
            home)               _complete_nix_cmd 2 nix shell "$configPath";;
            build|switch)       _complete_nix_cmd 2 nix build "$configPath";;
          esac fi
        }
        complete -F _config config
      '';

      home.file.".nix-defexpr/default.nix".text = ''
        let
          self = builtins.getFlake "config";
          machines = self.nixosConfigurations;
          local = machines.${strings.escapeNixIdentifier this.hostname};
        in rec {
          inherit self;
          inherit (self) inputs lib;
          inherit (lib) my;
          this = my.machines.${strings.escapeNixIdentifier this.hostname};
          inherit (local) config options;
          inherit (local.config.system.build) toplevel vm vmWithBootLoader manual;
        } // machines // local._module.args
      '';
    };
  };
}
