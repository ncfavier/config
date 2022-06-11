{ inputs, lib, config, ... }: with lib; {
  imports = [
    inputs.home-manager.nixosModule
    (mkAliasOptionModule [ "hm" ] [ "home-manager" "users" my.username ])
  ];

  system.extraDependencies = collectFlakeInputs inputs.home-manager;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
    extraSpecialArgs = { inherit inputs; };
  };

  hm = {
    home.stateVersion = config.system.stateVersion;
    home.enableNixpkgsReleaseCheck = false;

    systemd.user.startServices = "sd-switch";

    manual.html.enable = true;
  };
}
