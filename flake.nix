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
    lib = inputs.nixos.lib.extend (import ./lib.nix);
  in {
    nixosModules = lib.importDir ./modules;

    nixosConfigurations = lib.mapAttrs (name: localConfig:
      lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          hardware = inputs.nixos-hardware.nixosModules;
        };
        modules = builtins.attrValues inputs.self.nixosModules ++ [
          localConfig
          ({ config, utils, me, my, ... }: {
            _module.args = {
              me = "n";
              my = config.users.users.${me} // {
                realName = "Naïm Favier";
                domain = "monade.li";
                email = "${me}@${my.domain}";
                emailFor = what: "${what}@${my.domain}";
                pgpFingerprint = "D10BD70AF981C671C8EE4D288F23BAE560675CA3";
                shellPath = utils.toShellPath my.shell;
                mutableConfig = "${my.home}/git/config";
                mkMutableSymlink = path: config.myHm.lib.file.mkOutOfStoreSymlink
                  "${my.mutableConfig}${lib.removePrefix (toString inputs.self) (toString path)}";
              };
            };

            networking.hostName = name;

            system.configurationRevision = inputs.self.rev or "dirty-${inputs.self.lastModifiedDate}";
          })
        ];
      }
    ) (lib.importDir ./machines);
  };
}
