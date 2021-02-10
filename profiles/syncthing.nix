{ config, me, my, secretsPath, ... }: {
  sops.secrets = {
    syncthing-cert = {
      sopsFile = secretsPath + "/syncthing-cert.json";
      format = "json";
      key = config.networking.hostName;
    };
    syncthing-key = {
      sopsFile = secretsPath + "/syncthing-key.json";
      format = "json";
      key = config.networking.hostName;
    };
  };

  services.syncthing = {
    enable = true;
    user = me;
    inherit (my) group;
    dataDir = my.home;

    guiAddress = "10.42.0.1:8384"; # TODO host's IP
    openDefaultPorts = true;

    declarative = { # TODO insecureAdminAccess
      cert = config.sops.secrets.syncthing-cert.path;
      key = config.sops.secrets.syncthing-key.path;

      overrideDevices = true;
      devices = {
        mo = {
          id = "WO4GV6E-AJGKLLQ-M7RZGFT-WY7CCOW-LXODXRY-F3QPEJ2-AXDVWKR-SWBGDQP";
          introducer = true;
        };
        tsu = {
          id = "KXGLMP5-D2RKWZR-QUASDWC-T6H337M-HMEYLX7-D7EW4LM-UARXLZN-NXKVZAU";
          introducer = true;
        };
        fu = {
          id = "VVLGMST-LA633IY-KWESSFD-7FFF7LE-PNJAEML-ZXZSBLL-ATLQHPT-MUHEDAR";
          introducer = true;
        };
      };

      overrideFolders = true;
      folders = let
        trashcan = {
          type = "trashcan";
          params.cleanoutDays = "0";
        };
      in {
        my = {
          path = "${my.home}/my";
          devices = [ "fu" "mo" ];
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
          devices = [ "fu" "mo" "tsu" ];
          versioning = trashcan;
        };
        music = {
          path = "${my.home}/music";
          devices = [ "fu" "mo" "tsu" ];
          versioning = trashcan;
        };
        camera = {
          path = "${my.home}/camera";
          devices = [ "fu" "mo" "tsu" ];
          versioning = trashcan;
        };
        uploads = {
          path = "${my.home}/uploads";
          devices = [ "fu" "mo" ];
          versioning = trashcan;
        };
        saves = {
          path = "${my.home}/saves";
          devices = [ "fu" "mo" ];
          versioning = trashcan;
        };
        irc-logs = {
          path = "${my.home}/irc-logs";
          devices = [ "fu" "mo" ];
          watch = false;
          versioning = trashcan;
        };
      };
    };
  };
}
