{ inputs, config, lib, my, ... }: {
  imports = [
    inputs.home-manager.nixosModule
    (lib.mkAliasOptionModule [ "myHm" ] [ "home-manager" "users" my.username ])
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
    extraSpecialArgs = { inherit inputs; };
    sharedModules = [
      { home.stateVersion = config.system.stateVersion; }
    ];
  };
}
