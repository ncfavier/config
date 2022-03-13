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
      url = "github:ncfavier/home-manager/live";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "nur";
    nix-dns = {
      url = "github:kirelagin/nix-dns";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "nix-dns/flake-utils";
    };
    www = {
      url = "github:ncfavier/monade.li";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }: let
    lib = nixpkgs.lib.extend (import ./lib);
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    mkSystem = this: modules: lib.nixosSystem {
      inherit lib system modules;
      specialArgs = {
        inherit this;
        inputs = inputs // {
          hardware = nixpkgs.nixosModules // inputs.nixos-hardware.nixosModules;
        };
        pkgsBase = pkgs; # for use in imports without infinite recursion
      };
    };
  in with lib; {
    inherit lib;

    nixosConfigurations = mapAttrs (hostname: localConfig:
      mkSystem my.machines.${hostname} (attrValues (modulesIn ./modules) ++ [ localConfig ])
    ) (modulesIn ./machines);

    packages.${system} = mapAttrs (_: c: c.config.system.build.toplevel) self.nixosConfigurations // {
      iso = let
        inherit (mkSystem {} [ ./iso.nix ]) config;

        # horrible hack, see https://github.com/NixOS/nix/issues/5633
        involution = name: file: pkgs.runCommand name {} ''
          tr a-z0-9 n-za-m5-90-4 < ${escapeShellArg file} > "$out"
        '';
        nukeReferences = name: file: involution name (involution "${name}-rot" file);
      in
        nukeReferences "nixos.iso" "${config.system.build.isoImage}/iso/${config.isoImage.isoName}";
    };
  };
}
