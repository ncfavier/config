{ lib, this, config, ... }: with lib; let
  devices = my.machinesWith "syncthing";
  enable = this ? wireguard && this ? syncthing;
in {
  imports = [
    (mkAliasOptionModule [ "synced" ] [ "services" "syncthing" "settings" "folders" ])
  ];

  lib.shellEnv.synced = mapAttrs (_: v: v.path) config.synced;

  services.syncthing = {
    inherit enable;
    user = my.username;
    inherit (config.my) group;
    dataDir = config.my.home;
    overrideDevices = true;
    overrideFolders = true;

    guiAddress = "${this.wireguard.ipv4}:8384";
    openDefaultPorts = true;

    key = mkIf (this ? syncthing) config.secrets.syncthing.path;

    settings = {
      gui = {
        theme = "default";
        insecureAdminAccess = true;
      };
      options.urAccepted = -1;

      devices = mapAttrs (_: m: {
        inherit (m.syncthing) id;
        introducer = m.isServer;
      }) devices;

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
        allDevices = attrNames devices;
        allDevicesExceptPhone = attrNames (filterAttrs (_: m: !m.isPhone) devices);
      in {
        my = {
          path = "${config.my.home}/sync/my";
          devices = allDevices;
          versioning = simple;
        };
        pictures = {
          path = "${config.my.home}/sync/pictures";
          devices = allDevices;
          versioning = trashcan;
        };
        music = {
          path = "${config.my.home}/sync/music";
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
          fsWatcherEnabled = false;
          versioning = trashcan;
        };
        irc-logs = {
          path = "${config.my.home}/sync/irc-logs";
          type = if this.isServer then "sendonly" else "receiveonly";
          devices = allDevicesExceptPhone;
          fsWatcherEnabled = false;
          versioning = trashcan;
        };
        uploads = {
          path = "${config.my.home}/sync/uploads";
          devices = allDevicesExceptPhone;
          versioning = trashcan;
        };
        password-store = {
          path = "${config.my.home}/sync/password-store";
          devices = allDevices;
          versioning = simple;
        };
        mail = {
          path = if config.mailserver.enable or false
            then config.mailserver.mailDirectory
            else "${config.my.home}/sync/mail";
          type = if config.mailserver.enable or false then "sendonly" else "receiveonly";
          devices = allDevicesExceptPhone;
          versioning = simple;
        };
      };
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
