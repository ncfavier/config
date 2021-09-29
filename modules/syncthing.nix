{ lib, here, config, ... }: with lib; {
  imports = [
    (mkAliasOptionModule [ "synced" ] [ "services" "syncthing" "folders" ])
  ];

  lib.shellEnv.synced = mapAttrs (_: v: v.path) config.synced;

  secrets.syncthing = {
    format = "yaml";
    key = here.hostname;
  };

  services.syncthing = {
    enable = true;
    user = my.username;
    inherit (config.my) group;
    dataDir = config.my.home;

    guiAddress = "[${here.wireguard.ipv6}]:8384";
    openDefaultPorts = true;

    key = config.secrets.syncthing.path;

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
      password-store = {
        path = config.hm.programs.password-store.settings.PASSWORD_STORE_DIR;
        devices = allDevices;
        versioning = trashcan;
      };
    };

    extraOptions = {
      gui = {
        insecureAdminAccess = true;
        theme = "default";
      };
      options.urAccepted = -1;
    };
  };

  systemd.services.syncthing.environment.STNODEFAULTFOLDER = "yes";

  environment.systemPackages = [ config.services.syncthing.package ];

  hm.home.file = {
    "${config.synced.my.path}/.stignore".text = ''
      .git
    '';
    "${config.synced.saves.path}/.stignore".text = ''
      /df/current
    '';
    "${config.synced.uploads.path}/.stignore".text = ''
      /local
    '';
  };
}
