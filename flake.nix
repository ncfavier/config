{
  description = "ncfavier's configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-21.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-bash = {
      url = "github:ncfavier/home-manager/bash-init";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "nur";
    nix-dns = {
      url = "github:kirelagin/nix-dns/v1.1.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-21_05.follows = "nixpkgs-stable";
      inputs.utils.follows = "nix-dns/flake-utils";
    };
    www = {
      url = "github:ncfavier/monade.li";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    lib = nixpkgs.lib.extend (import ./lib inputs);
  in with lib; {
    inherit lib;

    nixosConfigurations = mapAttrs (hostname: localModule: nixosSystem {
      inherit system lib;
      specialArgs = {
        inherit inputs;
        pkgsFlake = pkgs;
        hardware = nixpkgs.nixosModules // inputs.nixos-hardware.nixosModules;
        here = my.machines.${hostname};
      };
      modules = attrValues (modulesIn ./modules) ++ [ localModule ];
    }) (modulesIn ./machines);

    packages.${system} = mapAttrs (_: c: c.config.system.build.toplevel) self.nixosConfigurations // {
      iso = let
        iso = (nixosSystem {
          inherit system lib;
          specialArgs = {
            inherit inputs;
            here = null;
          };
          modules = [ ./iso.nix ];
        }).config;

        # horrible hack, see https://github.com/NixOS/nix/issues/5633
        involution = name: file: pkgs.runCommand name {} ''
          tr a-z0-9 n-za-m5-90-4 < ${lib.escapeShellArg file} > "$out"
        '';
        nukeReferences = name: file: involution name (involution "${name}-rot" file);
      in
        nukeReferences "nixos.iso" "${iso.system.build.isoImage}/iso/${iso.isoImage.isoName}";
    };
  };
}
