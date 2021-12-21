{ inputs, lib, config, ... }: with lib; {
  imports = [
    inputs.home-manager.nixosModule
    (mkAliasOptionModule [ "hm" ] [ "home-manager" "users" my.username ])
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
    extraSpecialArgs = { inherit inputs; };
  };

  hm = {
    home.stateVersion = config.system.stateVersion;
    home.enableNixpkgsReleaseCheck = false;

    systemd.user.startServices = true;

    # manual.html.enable = true;
  };

  nix.gcRoots = [ inputs.home-manager inputs.home-manager-bash ];
}
