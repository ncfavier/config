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
    };
    "monade.li" = {
      url = "github:ncfavier/monade.li";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixos, ... }: let
    system = "x86_64-linux";
    pkgs = nixos.legacyPackages.${system};
    lib = nixos.lib.extend (import ./lib);
  in {
    inherit lib;

    nixosModules = lib.importDir ./modules;

    nixosConfigurations = lib.mapAttrs (hostname: local:
      lib.nixosSystem {
        inherit system lib; # https://github.com/NixOS/nixpkgs/pull/126769
        specialArgs = {
          inherit inputs;
          hardware = inputs.nixos-hardware.nixosModules;
          inherit (lib) my;
          here = lib.my.machines.${hostname} or {};
        };
        modules = builtins.attrValues self.nixosModules ++ [ local ];
      }
    ) (lib.importDir ./machines);

    devShell.${system} = pkgs.mkShell {
      packages = with pkgs; [ sops ];
      SOPS_PGP_FP = lib.my.pgpFingerprint;
    };

    packages.${system}.iso = (lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [ ./iso.nix ];
    }).config.system.build.isoImage;
  };
}
