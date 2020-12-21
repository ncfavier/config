{
  description = "ncfavier's configurations";

  inputs = {
    nixos.url          = "flake:nixpkgs/nixos-20.09";
    nixos-unstable.url = "flake:nixpkgs/nixos-unstable";
    nixos-hardware.url = "flake:nixos-hardware";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixos";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-20.09";
      inputs.nixpkgs.follows = "nixos";
    };
    dns = {
      url = "github:kirelagin/nix-dns";
      inputs.nixpkgs.follows = "nixos";
    };
    "monade.li" = {
      url = "github:ncfavier/monade.li";
      flake = false;
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixos";
    };
  };

  outputs = inputs: with inputs; let
    inherit (nixos-unstable) lib;

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
          profilesPath = toString "${self}/profiles";
        };
        modules = [
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          ({ config, pkgs, me, my, profilesPath, ... }: {
            imports = [ "${profilesPath}" ];

            _module.args = {
              pkgsUnstable = import nixos-unstable { inherit (config.nixpkgs) system; };

              me = "n";
              my = config.users.users.${me} // {
                realName = "Naïm Favier";
                email = "${me}@monade.li";
                emailFor = what: "${me}+${what}@monade.li";
              };
              myHm = config.home-manager.users.${me};
              configPath = "${my.home}/git/config";
              secretsPath = ./secrets;
            };

            networking.hostName = host;

            system.configurationRevision = self.rev or "dirty-${self.lastModifiedDate}";

            nix = {
              package = pkgs.nixFlakes;
              nixPath = [ "nixos=${nixos}" "nixpkgs=${nixos-unstable}" ];
              registry = {
                self.flake = self;
                nixos.flake = nixos;
                nixpkgs.flake = nixos-unstable;
              };
              extraOptions = ''
                experimental-features = nix-command flakes ca-references
              '';
            };

            sops = {
              gnupgHome = "${my.home}/.gnupg";
              sshKeyPaths = [];
              # validateSopsFiles = false;
            };

            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              verbose = true;
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
