{ inputs, config, pkgs, lib, my, ... }: let
  flakes = [ "self" "nixos" "nixos-stable" ];
in {
  nix = {
    package = pkgs.nixFlakes;

    trustedUsers = [ "root" "@wheel" ];

    nixPath = map (flake: "${flake}=${inputs.${flake}}") flakes ++ [ "nixpkgs=${inputs.nixos}" ];
    registry = lib.genAttrs flakes (flake: { flake = inputs.${flake}; });

    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;

    extraOptions = ''
      experimental-features = nix-command flakes ca-references
      warn-dirty = false
      keep-outputs = true
      keep-derivations = true
    '';
  };

  nixpkgs.config.allowUnfree = true;

  myHm.home.file.".nix-defexpr/default.nix".text = ''
    { mutable ? false }: let
      nixos = import (builtins.getFlake "nixos") {};
      nixpkgs = import (builtins.getFlake "nixpkgs") {};
      self = builtins.getFlake "self";
      mutableSelf = builtins.getFlake ${lib.strings.escapeNixString my.mutableConfig};
      inherit (nixos) lib;
      machines = (if mutable then mutableSelf else self).nixosConfigurations;
      local = machines.${lib.strings.escapeNixIdentifier config.networking.hostName};
    in {
      inherit nixos nixpkgs self mutableSelf lib local;
      inherit (local) config;
    } // machines // local._module.args
  '';
}
