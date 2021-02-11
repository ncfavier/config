{ config, lib, ... }: {
  options.home-manager.users = lib.mkOption {
    type = with lib.types; attrsOf (submoduleWith {
      modules = [
        {
          home.stateVersion = config.system.stateVersion;
        }
      ];
    });
  };

  config.home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
  };
}
