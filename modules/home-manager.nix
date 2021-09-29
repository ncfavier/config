{ inputs, lib, config, ... }: with lib; {
  imports = [
    inputs.home-manager.nixosModule
    (mkAliasOptionModule [ "hm" ] [ "home-manager" "users" my.username ])
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
    extraSpecialArgs = {
      inherit inputs;
      modulesPath = "${inputs.home-manager}/modules"; # https://github.com/nix-community/home-manager/pull/2354
    };
  };

  hm = {
    home.stateVersion = config.system.stateVersion;

    systemd.user.startServices = true;

    manual.html.enable = true;
  };

  nix.gcRoots = [ inputs.home-manager inputs.home-manager-bash ];
}
