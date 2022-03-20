{ inputs, lib, this, config, pkgs, ... }: with lib; {
  # work around issues like https://github.com/NixOS/nix/issues/3995 and https://github.com/NixOS/nix/issues/719
  options.nix.gcRoots = mkOption { # TODO remove
    description = "A list of garbage collector roots.";
    type = with types; listOf path;
    default = [];
  };

  config = {
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

    nix = {
      settings = {
        experimental-features = [ "nix-command" "flakes" "ca-derivations" ];
        warn-dirty = false;
        keep-outputs = true;
        trusted-users = [ "root" "@wheel" ];
      };

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

        nixpkgs.flake = inputs.nixpkgs;
      };

      nixPath = [ "nixpkgs=/etc/nixpkgs" ];

      gc = {
        automatic = true;
        options = "--delete-older-than 30d";
      };
      optimise.automatic = true;
      gcRoots = with inputs; [ nixpkgs nixpkgs-stable nixos-hardware nur ];
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
    environment.etc.gc-roots.text = concatMapStrings (x: x + "\n") config.nix.gcRoots;

    environment.variables.NIX_SHELL_PRESERVE_PROMPT = "1";

    environment.systemPackages = with pkgs; [
      config-cli
      nix-bash-completions
      nix-index-unwrapped # use the system-wide nix
      nix-prefetch-git
      nix-prefetch-github
      nix-diff
      nix-top
      nix-tree
      nixpkgs-fmt
      nixpkgs-review
      nixfmt
      rnix-lsp
    ];

    lib.shellEnv = {
      inherit (my) domain;
      server_hostname = my.server.hostname;
      inherit (this) isServer;
    };

    nixpkgs.overlays = [
      inputs.nur.overlay
      (pkgs: prev: {
        nix-bash-completions = prev.nix-bash-completions.overrideAttrs (o: {
          # let nix handle completion for the nix command
          postPatch = ''
            substituteInPlace _nix --replace 'nix nixos-option' 'nixos-option'
          '';
        });
      })
      (pkgs: prev: {
        config-cli = pkgs.writeShellScriptBin "config" ''
          configPath=${escapeShellArg config.lib.meta.configPath}
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
                  "echo unsupported input type \(.locked.type) (supported: github, gitlab)"
                end
              ')
              ;;
            update)
              if (( $# )); then
                args=()
                for input do args+=(--update-input "$input"); done
                exec nix flake lock "$configPath" "''${args[@]}"
              else
                exec nix flake update -v "$configPath"
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
              exec nix build -f ~/.nix-defexpr --json "$@" | jq -r .;;

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
              exec sudo nixos-rebuild -v --flake "$configPath" "$cmd" "$@";;
          esac
        '';
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
            compare|update) _complete_nix_cmd $cword nix flake lock "$configPath" --update-input;;
            repl|eval|bld)  compreply -W '-w --wip';;&
            repl)           _complete_nix_cmd 2 nix repl ~/.nix-defexpr;;
            eval)           _complete_nix_cmd 2 nix eval -f ~/.nix-defexpr --json;;
            bld)            _complete_nix_cmd 2 nix build -f ~/.nix-defexpr --json;;
            home)           _complete_nix_cmd 2 nix shell "$configPath";;
            build|switch)   _complete_nix_cmd 2 nix build "$configPath";;
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
          inherit (local) config;
          inherit (local.config.system.build) toplevel vm vmWithBootLoader manual;
        } // machines // local._module.args
      '';

      home.activation.updateNixpkgsTag = ''
        ${optionalString (inputs.nixpkgs ? rev) ''
        $DRY_RUN_CMD ${pkgs.git}/bin/git -C ${config.my.home}/git/nixpkgs tag -f current ${inputs.nixpkgs.rev} || true
        ''}
      '';
    };
  };
}
