{
  description = "ncfavier's configurations";

  inputs = {
    nixos.url = flake:nixpkgs/release-20.09;
    nixos-hardware.url = flake:nixos-hardware;
    home-manager.url = github:rycee/home-manager/bqv-flakes;
  };

  outputs = inputs: with inputs;
    let
      hosts = [ "wo" ];
    in {
      nixosConfigurations = nixos.lib.genAttrs hosts (host:
        nixos.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ({ pkgs, lib, ... }: {
              networking.hostName = host;

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

              system.configurationRevision = lib.mkIf (self ? rev) self.rev;
            })
            home-manager.nixosModules.home-manager
            (import (./hosts + "/${host}.nix"))
          ];
        }
      );
    };
}
