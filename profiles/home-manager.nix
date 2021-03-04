{ inputs, config, lib, me, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    (lib.mkAliasOptionModule [ "myHm" ] [ "home-manager" "users" me ])
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
  };

  myHm.home.stateVersion = config.system.stateVersion;
}
