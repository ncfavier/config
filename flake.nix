{
  description = "ncfavier's configurations";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-22.11";
    nixos-hardware.url = "nixos-hardware";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "nur";
    dns = {
      url = "github:kirelagin/dns.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "home-manager/utils";
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "home-manager/utils";
    };
    www = {
      url = "github:ncfavier/monade.li";
      flake = false;
    };
    bothendieck = {
      url = "github:ncfavier/bothendieck";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "home-manager/utils";
      inputs.qeval.follows = "qeval";
    };
    qeval = {
      url = "github:ncfavier/qeval";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "home-manager/utils";
      inputs.nur.follows = "nur";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }: let
    lib = (nixpkgs.lib.extend (_: _: home-manager.lib)).extend (import ./lib);
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    mkSystem = this: modules: lib.nixosSystem {
      inherit lib system modules;
      specialArgs = {
        inherit inputs this;
        hardware = nixpkgs.nixosModules // inputs.nixos-hardware.nixosModules;
        pkgsBase = pkgs; # for use in imports without infinite recursion
      };
    };
  in with lib; {
    inherit lib;

    nixosConfigurations = mapAttrs (hostname: localConfig:
      mkSystem my.machines.${hostname} (attrValues (modulesIn ./modules) ++ [ localConfig ])
    ) (modulesIn ./machines) // {
      iso = mkSystem {} [ ./iso.nix ];
    };

    packages.${system} = mapAttrs (_: c: c.config.system.build.toplevel)
      (builtins.removeAttrs self.nixosConfigurations [ "iso" ]) // {
      iso = let
        inherit (self.nixosConfigurations.iso) config;

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
