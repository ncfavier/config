{
  description = "ncfavier's configurations";

  inputs = {
    nixos.url = "nixpkgs/nixos-unstable";
    nixos-stable.url = "nixpkgs/nixos-21.05";
    nixos-hardware.url = "nixos-hardware";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixos";
    };
    home-manager = {
      url = "github:ncfavier/home-manager";
      inputs.nixpkgs.follows = "nixos";
    };
    nur.url = "nur";
    nix-dns = {
      url = "github:kirelagin/nix-dns";
      inputs.nixpkgs.follows = "nixos";
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixos";
      inputs.nixpkgs-21_05.follows = "nixos-stable";
    };
    www = {
      url = "github:ncfavier/monade.li";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixos, ... }: let
    system = "x86_64-linux";
    pkgs = nixos.legacyPackages.${system};
    lib = nixos.lib.extend (import ./lib inputs);
  in with lib; {
    inherit lib;

    nixosModules = importDir ./modules;

    nixosConfigurations = mapAttrs (hostname: local: nixosSystem {
      inherit system lib; # https://github.com/NixOS/nixpkgs/pull/126769
      specialArgs = {
        inherit inputs;
        hardware = nixos.nixosModules // inputs.nixos-hardware.nixosModules;
        here = my.machines.${hostname};
      };
      modules = attrValues self.nixosModules ++ [ local ];
    }) (importDir ./machines) // {
      iso = nixosSystem {
        inherit system lib;
        specialArgs = { inherit inputs; };
        modules = [ ./iso.nix ];
      };
    };

    packages.${system}.iso = self.nixosConfigurations.iso.config.system.build.isoImage;
  };
}
