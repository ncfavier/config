{ inputs, lib, this, config, pkgs, ... }: with lib; {
  config = mkMerge [
    {
      nixpkgs.overlays = let
        importNixpkgs = nixpkgs: import nixpkgs {
          inherit (config.nixpkgs) localSystem crossSystem config;
        };
      in [
        (pkgs: prev: {
          stable = importNixpkgs inputs.nixpkgs-stable;
          rev = rev: sha256: importNixpkgs (pkgs.fetchFromGitHub {
            owner = "NixOS";
            repo = "nixpkgs";
            inherit rev sha256;
          });
          pr = n: pkgs.rev "refs/pull/${toString n}/head";
          mine = rev: sha256: importNixpkgs (pkgs.fetchFromGitHub {
            owner = lib.my.githubUsername;
            repo = "nixpkgs";
            inherit rev sha256;
          });
          local = importNixpkgs "${config.my.home}/git/nixpkgs";
        })
      ];

      nix.settings = mkMerge [
        {
          experimental-features = [ "nix-command" "flakes" "ca-derivations" ];
          warn-dirty = false;
          trusted-users = [ "root" "@wheel" ];
          max-jobs = "auto";
          log-lines = 30;
          substituters = [
            "https://${my.githubUsername}.cachix.org"
            "https://nix-community.cachix.org"
          ];
          trusted-public-keys = [
            "${my.githubUsername}.cachix.org-1:RpBMt+EIZOwVwU1CW71cWZAVJ9DCNbCMsX8VOGSf3ME="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
        }
        (mkIf (! this.isServer) {
          substituters = [ "https://nix.${my.domain}" ];
          trusted-public-keys = [ "nix.${my.domain}:2Zgy59ai/edDBizXByHMqiGgaHlE04G6Nzuhx1RPFgo=" ];
        })
      ];
    }

    (mkIf (! this.isISO) {
      system.extraDependencies = concatMap collectFlakeInputs (with inputs; [
        nixpkgs nixpkgs-stable nixos-hardware nur
      ]);

      lib.meta = {
        configPath = "${config.my.home}/git/config";
        mkMutableSymlink = path: config.hm.lib.file.mkOutOfStoreSymlink
          (config.lib.meta.configPath + removePrefix (toString ./..) (toString path));
      };

      secrets.nix-access-tokens = {
        mode = "0440";
        group = config.users.groups.keys.name;
      };

      nix = {
        settings = {
          experimental-features = [ "auto-allocate-uids" ];
          keep-derivations = true;
          auto-allocate-uids = true;
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

        gc = mkIf (!this.isServer) {
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
            defexpr=${escapeShellArg "${config.hm.home.homeDirectory}/.nix-defexpr"}
            cmd=$1
            shift
            case $cmd in
              repl|eval|bld|run|rev)
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
                nix eval "''${flakeArgs[@]}" -f "$defexpr" --raw "$expr"
                echo
                ;;

              repl)
                exec nix repl "''${flakeArgs[@]}" -f "$defexpr" "$@";;
              eval)
                exec nix eval "''${flakeArgs[@]}" -f "$defexpr" --json "$@" | jq -r .;;
              bld)
                # https://github.com/NixOS/nix/issues/6661
                exec nix-build --log-format bar-with-logs "''${flakeArgs[@]}" "$defexpr" -A "$@";;
              run)
                exec nix run "''${flakeArgs[@]}" -f "$defexpr" "$@";;

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
            local cur prev words cword args_offset flakeArgs
            local configPath=${escapeShellArg config.lib.meta.configPath}
            _init_completion -n ':=&'
            if [[ $cword == 1 ]] || [[ $cword == 2 && $prev == @* ]]; then
              if [[ $cur == @* ]]; then
                _known_hosts_real -a -- "$cur"
              else
                compreply -W 'env compare update repl eval bld run specialise revert home build build-vm test switch boot'
              fi
            else
              args_offset=2
              flakeArgs=()
              case ''${words[1]} in
                repl|eval|bld|run|rev)
                  compreply -W '-w --wip'
                  while [[ ''${words[args_offset]} == @(-w|--wip) ]]; do
                    (( args_offset++ ))
                    flakeArgs+=(--override-flake config "$configPath")
                  done
                  ;;&
                compare|update|rev) _complete_nix_cmd $cword nix flake lock "$configPath" --update-input;;
                repl)               _complete_nix_cmd $args_offset nix repl "''${flakeArgs[@]}" ~/.nix-defexpr;;
                eval)               _complete_nix_cmd $args_offset nix eval "''${flakeArgs[@]}" -f ~/.nix-defexpr;;
                bld)                _complete_nix_cmd $args_offset nix build "''${flakeArgs[@]}" -f ~/.nix-defexpr;;
                run)                _complete_nix_cmd $args_offset nix run "''${flakeArgs[@]}" -f ~/.nix-defexpr;;
                home)               _complete_nix_cmd $args_offset nix shell "$configPath";;
                build|switch)       _complete_nix_cmd $args_offset nix build "$configPath";;
              esac
            fi
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
    })
  ];
}
