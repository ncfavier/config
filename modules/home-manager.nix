{ inputs, lib, config, ... }: with lib; {
  imports = [
    inputs.home-manager.nixosModules.default
    (mkAliasOptionModule [ "hm" ] [ "home-manager" "users" my.username ])
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
    extraSpecialArgs = { inherit inputs; };
  };

  hm = {
    imports = [
      inputs.xhmm.homeManagerModules.languages.haskell
    ];

    home.stateVersion = config.system.stateVersion;
    home.enableNixpkgsReleaseCheck = false;

    systemd.user.startServices = "sd-switch";

    manual.html.enable = true;
  };
}
