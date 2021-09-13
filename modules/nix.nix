{ inputs, lib, here, config, utils, pkgs, ... }: with lib; {
  _module.args = {
    utils.importNixpkgs = nixpkgs: import nixpkgs {
      inherit (config.nixpkgs) localSystem crossSystem config;
    };

    pkgsStable = utils.importNixpkgs inputs.nixos-stable;
    pkgsLocal = utils.importNixpkgs "${config.my.home}/git/nixpkgs"; # only available in --impure mode
    pkgsPR = pr: sha256: utils.importNixpkgs (pkgs.fetchFromGitHub {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "refs/pull/${toString pr}/head";
      inherit sha256;
    });
  };

  nix = {
    package = pkgs.nixUnstable;

    trustedUsers = [ "root" "@wheel" ];

    registry = mapAttrs (_: flake: { inherit flake; }) (removeAttrs inputs [ "self" ]) // {
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

    extraOptions = ''
      experimental-features = nix-command flakes ca-references ca-derivations
      warn-dirty = false
      keep-outputs = true
      keep-derivations = true
    '';
  };

  nixpkgs.overlays = [
    inputs.nur.overlay
    (self: super: {
      nix-index = super.nix-index.override { nix = config.nix.package; };
      nix-bash-completions = super.nix-bash-completions.overrideAttrs (o: {
        # let nix handle completion for the nix command
        postPatch = ''
          substituteInPlace _nix --replace 'nix nixos-option' 'nixos-option'
        '';
      });
    })
  ];
  cachix.derivationsToPush = [ pkgs.nix-index ];

  environment.systemPackages = with pkgs; [
    nix-bash-completions
    nix-index
    nix-prefetch-github
    nix-diff
    nix-top
    nix-tree
    nixpkgs-fmt
    nixpkgs-review
    nixfmt
  ];

  environment.sessionVariables.NIX_SHELL_PRESERVE_PROMPT = "1";

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
}
