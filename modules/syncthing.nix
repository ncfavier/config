{ lib, here, config, secrets, syncedFolders, ... }: with lib; {
  _module.args.syncedFolders = config.services.syncthing.declarative.folders;
  lib.shellEnv.syncedFolders = mapAttrs (_: v: v.path) syncedFolders;

  sops.secrets.syncthing = {
    format = "yaml";
    key = here.hostname;
  };

  # TODO insecureAdminAccess, default Sync folder, anonymous usage reporting
  services.syncthing = {
    enable = true;
    user = my.username;
    inherit (config.my) group;
    dataDir = config.my.home;

    guiAddress = "[${here.wireguard.ipv6}]:8384";
    openDefaultPorts = true;

    declarative = {
      key = secrets.syncthing.path;

      overrideDevices = true;
      devices = mapAttrs (_: m: {
        inherit (m.syncthing) id;
        introducer = true;
      }) my.machines;

      overrideFolders = true;
      folders = let
        trashcan = {
          type = "trashcan";
          params.cleanoutDays = "0";
        };
        allDevices = attrNames my.machines;
        allDevicesExceptPhone = attrNames (filterAttrs (_: m: !m.isPhone) my.machines);
      in {
        my = {
          path = "${config.my.home}/my";
          devices = allDevices;
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
          devices = allDevices;
          versioning = trashcan;
        };
        music = {
          path = "${config.my.home}/music";
          devices = allDevices;
          versioning = trashcan;
        };
        camera = {
          path = "${config.my.home}/camera";
          devices = allDevices;
          versioning = trashcan;
        };
        saves = {
          path = "${config.my.home}/saves";
          devices = allDevicesExceptPhone;
          versioning = trashcan;
        };
        irc-logs = {
          path = "${config.my.home}/irc-logs";
          devices = allDevicesExceptPhone;
          watch = false;
          versioning = trashcan;
        };
        uploads = {
          path = "${config.my.home}/uploads";
          devices = allDevicesExceptPhone;
          versioning = trashcan;
        };
      };
    };
  };

  hm.home.file = {
    "${syncedFolders.my.path}/.stignore".text = ''
      .git
    '';
    "${syncedFolders.saves.path}/.stignore".text = ''
      df/current
    '';
  };
}
