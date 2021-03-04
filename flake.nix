{
  description = "ncfavier's configurations";

  inputs = {
    nixos.url          = "flake:nixpkgs/nixos-unstable";
    nixos-stable.url   = "flake:nixpkgs/nixos-20.09";
    nixpkgs-mine.url   = "github:ncfavier/nixpkgs";
    nixos-hardware.url = "flake:nixos-hardware";
    sops-nix = {
      url = "github:ncfavier/sops-nix";
      inputs.nixpkgs.follows = "nixos";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixos";
    };
    dns = {
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

  outputs = inputs: let
    inherit (inputs.nixos) lib;

    importDir = { dir, _import ? _: f: import f }: lib.pipe dir [
      builtins.readDir
      (lib.filterAttrs (n: v: v == "regular" && lib.hasSuffix ".nix" n && n != "default.nix"))
      (lib.mapAttrs' (n: v: rec {
        name = lib.removeSuffix ".nix" n;
        value = _import name "${toString dir}/${n}";
      }))
    ];
  in {
    nixosConfigurations = importDir { dir = ./hosts; _import = host: localModule:
      lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          hardware = inputs.nixos-hardware.nixosModules;

          profilesPath = toString ./profiles;
        };
        modules = builtins.attrValues inputs.self.nixosModules ++ [
          ({ config, utils, me, my, profilesPath, ... }: {
            imports = [ "${profilesPath}" localModule ];

            # TODO move _module.args into separate modules?
            _module.args = {
              pkgsStable = import inputs.nixos-stable {
                inherit (config.nixpkgs) localSystem crossSystem config overlays;
              };

              me = "n";
              my = config.users.users.${me} // {
                realName = "Naïm Favier";
                domain = "monade.li";
                email = "${me}@${my.domain}";
                emailFor = what: "${me}+${what}@${my.domain}";
                pgpFingerprint = "D10BD70AF981C671C8EE4D288F23BAE560675CA3";
                shellPath = utils.toShellPath my.shell;
                mutableConfig = "${my.home}/git/config";
              };
              secrets = config.sops.secrets;
              syncedFolders = config.services.syncthing.declarative.folders;
            };

            networking.hostName = host;

            system.configurationRevision = inputs.self.rev or "dirty-${inputs.self.lastModifiedDate}";
          })
        ];
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
