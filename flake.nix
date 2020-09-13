{
  description = "ncfavier's configurations";

  inputs = {
    nixos.url = flake:nixpkgs/release-20.09;
    nixos-hardware.url = flake:nixos-hardware;
    home-manager.url = github:rycee/home-manager/bqv-flakes;
  };

  outputs = inputs: with inputs; let
    nixosSystem = hostname: nixos.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          networking.hostName = hostname;

          nix = {
            package = pkgs.nixFlakes;
            extraOptions = ''
              experimental-features = nix-command flakes ca-references
            '';
            registry = {
              config.flake = self;
              nixos.flake = nixos;
            };
          };

          system.configurationRevision = self.rev;
        })
        home-manager.nixosModules.home-manager
        (import (./hosts + "/${hostname}.nix"))
      ];
    };
  in {
    nixosConfigurations = nixos.lib.genAttrs [ "wo" ] nixosSystem;
  };
}
