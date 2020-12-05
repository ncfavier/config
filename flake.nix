{
  description = "ncfavier's configurations";

  inputs = {
    nixpkgs.url = "flake:nixpkgs";
    nixos.url = "flake:nixpkgs/release-20.09";
    nixos-hardware.url = "flake:nixos-hardware";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixos";
    };
    home-manager = {
      url = "github:rycee/home-manager/release-20.09";
      inputs.nixpkgs.follows = "nixos";
    };
    "monade.li" = {
      url = "github:ncfavier/monade.li";
      flake = false;
    };
    simple-nixos-mailserver = {
      url = "gitlab:ncfavier/nixos-mailserver";
      inputs.nixpkgs.follows = "nixos";
    };
  };

  outputs = inputs: with inputs; let
    inherit (nixos) lib;

    importDir = { dir, _import ? _: f: import f }: lib.pipe dir [
      builtins.readDir
      (lib.filterAttrs (n: v: v == "regular" && lib.hasSuffix ".nix" n && n != "default.nix"))
      (lib.mapAttrs' (n: v: rec {
        name = lib.removeSuffix ".nix" n;
        value = _import name "${toString dir}/${n}";
      }))
    ];
  in {
    nixosConfigurations = importDir { dir = ./hosts; _import = host: path:
      lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          secretsPath = toString ./secrets;
          profilesPath = toString ./profiles;
        };
        modules =
          [
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            simple-nixos-mailserver.nixosModule
            ({ config, pkgs, me, my, ... }: {
              _module.args = {
                pkgsUnstable = import nixpkgs { inherit (config.nixpkgs) system; };

                me = "n";
                my = config.users.users.${me} // {
                  realName = "Naïm Favier";
                  email = "${me}@monade.li";
                  emailFor = what: "${me}+${what}@monade.li";
                };
                myHm = config.home-manager.users.${me};
                configPath = "${my.home}/git/config";
              };

              networking.hostName = host;

              system.configurationRevision = self.rev or "dirty-${self.lastModifiedDate}";

              nix = {
                package = pkgs.nixFlakes;
                nixPath = [ "nixpkgs=${nixpkgs}" "nixos=${nixos}" ];
                registry = {
                  config.flake = self;
                  nixos.flake = nixos;
                };
                extraOptions = ''
                  experimental-features = nix-command flakes ca-references
                '';
              };

              sops = {
                gnupgHome = "${my.home}/.gnupg";
                sshKeyPaths = [];
                validateSopsFiles = false;
              };
            })
            path
          ] ++ builtins.attrValues self.nixosModules;
      };
    };

    nixosModules = importDir { dir = ./modules; };

    #nixosProfiles = importDir { dir = ./profiles; _import = name: path:
    #  with lib; let
    #    profile = import path;
    #    profileF = if isFunction profile then profile else const profile;
    #  in setFunctionArgs (args@{ config, lib, ... }: {
    #    options.profiles.${name}.enable = lib.mkEnableOption name;
    #    config = lib.mkIf config.profiles.${name}.enable (profileF args);
    #  }) (functionArgs profileF);
    #};
  };
}
