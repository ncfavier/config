{ config, lib, hostName, here, secrets, me, my, syncedFolders, ... }: {
  _module.args.syncedFolders = config.services.syncthing.declarative.folders;

  sops.secrets.syncthing = {
    format = "json";
    key = hostName;
  };

  services.syncthing = {
    enable = true;
    user = me;
    inherit (my) group;
    dataDir = my.home;

    guiAddress = "[${here.wireguard.ipv6}]:8384";
    openDefaultPorts = true;

    declarative = { # TODO insecureAdminAccess
      key = secrets.syncthing.path;

      overrideDevices = true;
      devices = lib.mapAttrs (_: m: {
        inherit (m.syncthing) id;
        introducer = true;
      }) config.machines;

      overrideFolders = true;
      folders = let
        trashcan = {
          type = "trashcan";
          params.cleanoutDays = "0";
        };
      in {
        my = {
          path = "${my.home}/my";
          devices = [ "wo" "fu" "mo" ];
          versioning = {
            type = "simple";
            params = {
              keep = "5";
              cleanoutDays = "0";
            };
          };
        };
        pictures = {
          path = "${my.home}/pictures";
          devices = [ "wo" "fu" "mo" "tsu" ];
          versioning = trashcan;
        };
        music = {
          path = "${my.home}/music";
          devices = [ "wo" "fu" "mo" "tsu" ];
          versioning = trashcan;
        };
        camera = {
          path = "${my.home}/camera";
          devices = [ "wo" "fu" "mo" "tsu" ];
          versioning = trashcan;
        };
        saves = {
          path = "${my.home}/saves";
          devices = [ "wo" "fu" "mo" ];
          versioning = trashcan;
        };
        irc-logs = {
          path = "${my.home}/irc-logs";
          devices = [ "wo" "fu" "mo" ];
          watch = false;
          versioning = trashcan;
        };
        uploads = {
          path = "${my.home}/uploads";
          devices = [ "wo" "fu" "mo" ];
          versioning = trashcan;
        };
      };
    };
  };
}
