{ inputs, lib, here, config, utils, pkgs, ... }: with lib; {
  # work around issues like https://github.com/NixOS/nix/issues/3995 and https://github.com/NixOS/nix/issues/719
  options.nix.gcRoots = mkOption {
    description = "A list of garbage collector roots.";
    type = with types; listOf path;
    default = [];
  };

  config = {
    _module.args = {
      utils.importNixpkgs = nixpkgs: import nixpkgs {
        inherit (config.nixpkgs) localSystem crossSystem config;
      };

      pkgsStable = utils.importNixpkgs inputs.nixpkgs-stable;
      pkgsLocal = utils.importNixpkgs "${config.my.home}/git/nixpkgs"; # only available in --impure mode
      pkgsBranch = rev: sha256: utils.importNixpkgs (pkgs.fetchFromGitHub {
        owner = my.githubUsername;
        repo = "nixpkgs";
        inherit rev sha256;
      });
      pkgsPR = pr: sha256: utils.importNixpkgs (pkgs.fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs";
        rev = "refs/pull/${toString pr}/head";
        inherit sha256;
      });
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
            url = "file:${utils.configPath}";
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

    environment.etc.nixpkgs.source = inputs.nixpkgs;

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
    ];

    environment.systemPackages = with pkgs; [
      nix-bash-completions
      nix-index-unwrapped # use the system-wide Nix
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

    # systemd.services.nix-index = {
    #   description = "Regenerate nix-index database";
    #   serviceConfig.User = my.username;
    #   script = ''
    #     ${pkgs.nix-index-unwrapped}/bin/nix-index
    #   '';
    #   startAt = "Mon 04:15";
    # };

    environment.variables.NIX_SHELL_PRESERVE_PROMPT = "1";

    environment.etc.gc-roots.text = concatMapStrings (x: x + "\n") config.nix.gcRoots;

    hm.home.file.".nix-defexpr/default.nix".text = ''
      let
        self = builtins.getFlake "config";
        machines = self.nixosConfigurations;
        local = machines.${strings.escapeNixIdentifier here.hostname};
      in rec {
        inherit self;
        inherit (self) inputs lib;
        inherit (lib) my;
        here = my.machines.${strings.escapeNixIdentifier here.hostname};
        inherit (local) config;
        inherit (local.config.system.build) toplevel vm vmWithBootLoader manual;
      } // machines // local._module.args
    '';

    hm.home.activation.updateNixpkgsTag = ''
      ${optionalString (inputs.nixpkgs ? rev) ''
      $DRY_RUN_CMD ${pkgs.git}/bin/git -C ${config.my.home}/git/nixpkgs tag -f current ${inputs.nixpkgs.rev} || true
      ''}
    '';
  };
}
