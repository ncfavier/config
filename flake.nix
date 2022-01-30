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
    lib = nixpkgs.lib.extend (import ./lib);
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in with lib; {
    inherit lib;

    nixosConfigurations = mapAttrs (hostname: localModule: nixosSystem {
      inherit lib system;
      modules = attrValues (modulesIn ./modules) ++ [ localModule ];
      specialArgs = {
        inherit inputs;
        pkgsFlake = pkgs;
        hardware = nixpkgs.nixosModules // inputs.nixos-hardware.nixosModules;
        here = my.machines.${hostname};
      };
    }) (modulesIn ./machines);

    packages.${system} = mapAttrs (_: c: c.config.system.build.toplevel) self.nixosConfigurations // {
      iso = let
        inherit (nixosSystem {
          inherit lib system;
          modules = [ ./iso.nix ];
          specialArgs = {
            inherit inputs;
            here = null;
          };
        }) config;

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
