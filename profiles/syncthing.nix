{ config, lib, me, my, secretPath, secrets, syncedFolders, ... }: {
  sops.secrets = {
    syncthing-cert = {
      sopsFile = secretPath "syncthing-cert.json";
      format = "json";
      key = config.networking.hostName;
    };
    syncthing-key = {
      sopsFile = secretPath "syncthing-key.json";
      format = "json";
      key = config.networking.hostName;
    };
  };

  services.syncthing = {
    enable = true;
    user = me;
    inherit (my) group;
    dataDir = my.home;

    guiAddress = "[fd42::0:1]:8384"; # TODO support other machines
    openDefaultPorts = true;

    declarative = { # TODO insecureAdminAccess
      cert = secrets.syncthing-cert.path;
      key = secrets.syncthing-key.path;

      overrideDevices = true;
      devices = {
        wo = {
          id = "7YQ7LRQ-IAWYNHN-VGHTAEQ-JDSH3C7-DUPWBYD-G6L4OJC-W3YLUFZ-SSM5CA6";
          introducer = true;
        };
        fu = {
          id = "VVLGMST-LA633IY-KWESSFD-7FFF7LE-PNJAEML-ZXZSBLL-ATLQHPT-MUHEDAR";
          introducer = true;
        };
        mo = {
          id = "WO4GV6E-AJGKLLQ-M7RZGFT-WY7CCOW-LXODXRY-F3QPEJ2-AXDVWKR-SWBGDQP";
          introducer = true;
        };
        tsu = {
          id = "KXGLMP5-D2RKWZR-QUASDWC-T6H337M-HMEYLX7-D7EW4LM-UARXLZN-NXKVZAU";
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
