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
    package = pkgs.nixFlakes;

    trustedUsers = [ "root" "@wheel" ];

    registry = {
      config.flake = inputs.self;
      nixos.flake = inputs.nixos;
      nixpkgs.flake = inputs.nixos;
      nixos-stable.flake = inputs.nixos-stable;
    };

    nixPath = [ "nixpkgs=${pkgs.writeText "nixpkgs.nix" ''
      import (builtins.getFlake "nixos")
    ''}" ];

    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;

    extraOptions = ''
      experimental-features = nix-command flakes ca-derivations ca-references
      warn-dirty = false
      keep-outputs = true
      keep-derivations = true
    '';
  };

  nixpkgs = {
    overlays = [ inputs.nur.overlay ];
    config.allowUnfree = true; # :(
  };

  environment.systemPackages = with pkgs; [
    (lowPrio nix-bash-completions)
    (pkgs.nix-index.override { nix = nixFlakes; })
    nix-diff
    nix-top
    nix-tree
    nix-prefetch-github
    nixpkgs-fmt
    nixpkgs-review
    nixfmt
    hydra-check
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
