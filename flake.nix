{
  description = "ncfavier's configurations";

  inputs = {
    nixos.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-stable.url = "github:NixOS/nixpkgs/nixos-21.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixos";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixos";
    };
    home-manager-bash = {
      url = "github:ncfavier/home-manager/bash-init";
      inputs.nixpkgs.follows = "nixos";
    };
    nur.url = "nur";
    nix-dns = {
      url = "github:kirelagin/nix-dns/v1.1.2";
      inputs.nixpkgs.follows = "nixos";
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixos";
      inputs.nixpkgs-21_05.follows = "nixos-stable";
      inputs.utils.follows = "nix-dns/flake-utils";
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

    nixosConfigurations = mapAttrs (hostname: localModule: nixosSystem {
      inherit system lib;
      specialArgs = {
        inherit inputs;
        pkgsFlake = pkgs;
        hardware = nixos.nixosModules // inputs.nixos-hardware.nixosModules;
        here = my.machines.${hostname};
      };
      modules = attrValues (modulesIn ./modules) ++ [ localModule ];
    }) (modulesIn ./machines) // {
      iso = nixosSystem {
        inherit system lib;
        specialArgs = {
          inherit inputs;
          here = null;
        };
        modules = [ ./iso.nix ];
      };
    };

    # horrible hack, see https://github.com/NixOS/nix/issues/5633
    packages.${system}.iso = let
      involution = name: file: pkgs.runCommand name {} ''
        tr a-z0-9 n-za-m5-90-4 < ${lib.escapeShellArg file} > "$out"
      '';
      nukeReferences = name: file: involution name (involution "${name}-rot" file);
      iso = self.nixosConfigurations.iso.config;
    in nukeReferences "nixos.iso" "${iso.system.build.isoImage}/iso/${iso.isoImage.isoName}";
  };
}
