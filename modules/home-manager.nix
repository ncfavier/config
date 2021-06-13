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
  };

  myHm = {
    home.stateVersion = config.system.stateVersion;

    systemd.user.startServices = true;

    manual.html.enable = true;
  };
}
