{ config, lib, me, ... }: {
  imports = [ (lib.mkAliasOptionModule [ "myHm" ] [ "home-manager" "users" me ]) ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
  };

  myHm.home.stateVersion = config.system.stateVersion;
}
