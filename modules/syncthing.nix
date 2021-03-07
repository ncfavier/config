{ config, lib, hostname, here, secrets, my, ... }: {
  _module.args.syncedFolders = config.services.syncthing.declarative.folders;

  sops.secrets.syncthing = {
    format = "json";
    key = hostname;
  };

  services.syncthing = {
    enable = true;
    user = my.username;
    inherit (config.my) group;
    dataDir = config.my.home;

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
          path = "${config.my.home}/my";
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
          path = "${config.my.home}/pictures";
          devices = [ "wo" "fu" "mo" "tsu" ];
          versioning = trashcan;
        };
        music = {
          path = "${config.my.home}/music";
          devices = [ "wo" "fu" "mo" "tsu" ];
          versioning = trashcan;
        };
        camera = {
          path = "${config.my.home}/camera";
          devices = [ "wo" "fu" "mo" "tsu" ];
          versioning = trashcan;
        };
        saves = {
          path = "${config.my.home}/saves";
          devices = [ "wo" "fu" "mo" ];
          versioning = trashcan;
        };
        irc-logs = {
          path = "${config.my.home}/irc-logs";
          devices = [ "wo" "fu" "mo" ];
          watch = false;
          versioning = trashcan;
        };
        uploads = {
          path = "${config.my.home}/uploads";
          devices = [ "wo" "fu" "mo" ];
          versioning = trashcan;
        };
      };
    };
  };
}
