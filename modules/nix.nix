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

      pkgsStable = utils.importNixpkgs inputs.nixos-stable;
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
      trustedUsers = [ "root" "@wheel" ];

      registry = {
        config.flake = inputs.self;
        nixpkgs.flake = inputs.nixos;
      };

      nixPath = [ "nixpkgs=${pkgs.writeText "nixpkgs.nix" ''
        import (builtins.getFlake "nixpkgs")
      ''}" ];

      gc = {
        automatic = true;
        options = "--delete-older-than 30d";
      };
      optimise.automatic = true;
      gcRoots = with inputs; [ nixos nixos-stable nixos-hardware nur ];

      extraOptions = ''
        experimental-features = nix-command flakes ca-derivations
        warn-dirty = false
        keep-outputs = true
        keep-derivations = true
      '';
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

    # TODO nix-index service
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
      { wip ? false }: let
        self = builtins.getFlake (if wip then ${strings.escapeNixString utils.configPath} else "config");
        machines = self.nixosConfigurations;
        local = machines.${strings.escapeNixIdentifier here.hostname};
      in rec {
        inherit self;
        inherit (self) inputs lib;
        inherit (lib) my;
        here = my.machines.${strings.escapeNixIdentifier here.hostname};
        inherit (local) config;
      } // machines // local._module.args
    '';
  };
}
