{ lib, ... }: {
  #options.home-manager.users = lib.mkOption {
  #  type = with lib.types; attrsOf (submoduleWith {
  #    modules = [];
  #  });
  #};

  config.home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
  };
}
