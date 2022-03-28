{ lib, this, config, ... }: with lib; {
  imports = [
    (mkAliasOptionModule [ "synced" ] [ "services" "syncthing" "folders" ])
  ];

  lib.shellEnv.synced = mapAttrs (_: v: v.path) config.synced;

  services.syncthing = {
    enable = true;
    user = my.username;
    inherit (config.my) group;
    dataDir = config.my.home;

    guiAddress = "0.0.0.0:8384";
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
      simple = {
        type = "simple";
        params = {
          keep = "5";
          cleanoutDays = "0";
        };
      };
      allDevices = attrNames my.machines;
      allDevicesExceptPhone = attrNames (filterAttrs (_: m: !m.isPhone) my.machines);
    in {
      my = {
        path = "${config.my.home}/my";
        devices = allDevices;
        versioning = simple;
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
        path = "${config.my.home}/sync/camera";
        devices = allDevices;
        versioning = trashcan;
      };
      saves = {
        path = "${config.my.home}/sync/saves";
        devices = allDevicesExceptPhone;
        versioning = trashcan;
      };
      irc-logs = {
        path = "${config.my.home}/sync/irc-logs";
        devices = allDevicesExceptPhone;
        watch = false;
        versioning = trashcan;
      };
      uploads = {
        path = "${config.my.home}/sync/uploads";
        devices = allDevicesExceptPhone;
        versioning = trashcan;
      };
      password-store = {
        path = config.hm.programs.password-store.settings.PASSWORD_STORE_DIR;
        devices = allDevices;
        versioning = simple;
      };
      mail = {
        path = if config.mailserver.enable or false
          then config.mailserver.mailDirectory
          else "${config.my.home}/sync/mail";
        devices = allDevicesExceptPhone;
        versioning = simple;
      };
    };

    extraOptions = {
      gui.theme = "default";
      options.urAccepted = -1;
    };
  };

  systemd.services.syncthing = {
    after = [ "home-manager-${my.username}.service" ]; # ensure ~/.config is created
    environment.STNODEFAULTFOLDER = "yes";
    serviceConfig.StartLimitIntervalSec = "1min";
    serviceConfig.StartLimitBurst = 5;
  };

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
