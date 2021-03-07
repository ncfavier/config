{
  description = "ncfavier's configurations";

  inputs = {
    nixos.url          = "flake:nixpkgs/nixos-unstable";
    nixos-stable.url   = "flake:nixpkgs/nixos-20.09";
    my-nixpkgs.url     = "github:ncfavier/nixpkgs";
    nixos-hardware.url = "flake:nixos-hardware";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixos";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixos";
    };
    nix-dns = {
      url = "github:kirelagin/nix-dns";
      inputs.nixpkgs.follows = "nixos";
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixos";
    };
    "monade.li" = {
      url = "github:ncfavier/monade.li";
      flake = false;
    };
  };

  outputs = inputs@{ self, ... }: let
    system = "x86_64-linux";
    pkgs = inputs.nixos.legacyPackages.${system};
    lib = inputs.nixos.lib.extend (import ./lib.nix);
    my = import ./my.nix lib;
  in {
    nixosModules = lib.importDir ./modules;

    nixosConfigurations = lib.mapAttrs (hostname: localConfig:
      lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs hostname my;
          here = my.machines.${hostname};
          hardware = inputs.nixos-hardware.nixosModules;
        };
        modules = builtins.attrValues self.nixosModules ++ [
          { system.configurationRevision = self.rev or "dirty-${self.lastModifiedDate}"; }
          localConfig
        ];
      }
    ) (lib.importDir ./machines);

    devShell.${system} = pkgs.mkShell {
      buildInputs = [ pkgs.sops ];
      SOPS_PGP_FP = my.pgpFingerprint;
    };
  };
}
