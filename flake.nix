{
  description = "ncfavier's configurations";

  inputs = {
    nixos.url          = "flake:nixpkgs/nixos-unstable";
    nixos-stable.url   = "flake:nixpkgs/nixos-20.09";
    nixpkgs-mine.url   = "github:ncfavier/nixpkgs";
    nixos-hardware.url = "flake:nixos-hardware";
    sops-nix = {
      url = "github:ncfavier/sops-nix";
      inputs.nixpkgs.follows = "nixos";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixos";
    };
    dns = {
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
    lib = inputs.nixos.lib.extend (import ./lib.nix);
  in {
    nixosModules = lib.importDir ./modules;

    nixosConfigurations = lib.mapAttrs (hostName: localConfig:
      lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs hostName;
          me = "n";
          domain = "monade.li";
          hardware = inputs.nixos-hardware.nixosModules;
        };
        modules = builtins.attrValues self.nixosModules ++ [
          localConfig
          {
            system.configurationRevision = self.rev or "dirty-${self.lastModifiedDate}";
          }
        ];
      }
    ) (lib.importDir ./machines);
  };
}
