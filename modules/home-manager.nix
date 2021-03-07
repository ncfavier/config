{ inputs, config, lib, my, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    (lib.mkAliasOptionModule [ "myHm" ] [ "home-manager" "users" my.username ])
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
  };

  myHm.home.stateVersion = config.system.stateVersion;
}
