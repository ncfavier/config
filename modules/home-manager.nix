{ inputs, lib, my, config, ... }: {
  imports = [
    inputs.home-manager.nixosModule
    (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" my.username ])
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
    extraSpecialArgs = { inherit inputs; };
  };

  hm = {
    home.stateVersion = config.system.stateVersion;

    systemd.user.startServices = true;

    manual.html.enable = true;
  };
}
