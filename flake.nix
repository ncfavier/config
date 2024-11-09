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
    xhmm.url = "github:schuelermine/xhmm";
    nur.url = "nur";
    dns = {
      url = "github:kirelagin/dns.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    www = {
      url = "github:ncfavier/monade.li";
      flake = false;
    };
    bothendieck = {
      url = "github:ncfavier/bothendieck";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.qeval.follows = "qeval";
    };
    nixpkgs-qeval.url = "nixpkgs/nixos-unstable";
    qeval = {
      url = "github:ncfavier/qeval";
      inputs.nixpkgs.follows = "nixpkgs-qeval";
      inputs.nur.follows = "nur";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }: let
    lib = (nixpkgs.lib.extend (_: _: home-manager.lib)).extend (import ./lib machines);
    machines = lib.exprsIn ./machines;
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in with lib; {
    inherit lib;

    nixosConfigurations = mapAttrs (k: nixos: let
      this = my.machines.${k};
    in
      lib.nixosSystem {
        inherit lib system;
        modules = optionals (! this.isISO) (attrValues (modulesIn ./modules)) ++ [
          { system.configurationRevision = self.rev or "dirty"; }
          nixos
        ];
        specialArgs = {
          inherit inputs this;
          myModulesPath = toString ./modules;
          hardware = nixpkgs.nixosModules // inputs.nixos-hardware.nixosModules;
          pkgsBase = pkgs; # for use in imports without infinite recursion
        };
      }
    ) (catAttrs' "nixos" machines);

    packages.${system} = mapAttrs (_: c: c.config.system.build.toplevel) self.nixosConfigurations // {
      iso = self.nixosConfigurations.iso.config.system.build.isoImage.overrideAttrs {
        unsafeDiscardReferences.out = true;
      };
    };
  };
}
