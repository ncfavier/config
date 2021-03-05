{ config, lib, hostName, ... }: {
  options.machines = lib.mkOption {
    type = with lib.types; attrsOf (submodule {
      options = {
        isServer = lib.mkOption {
          type = bool;
          default = false;
        };

        isStation = lib.mkOption {
          type = bool;
          default = false;
        };

        wireguard = {
          ipv4 = lib.mkOption {
            type = str;
          };
          ipv6 = lib.mkOption {
            type = str;
          };
          publicKey = lib.mkOption {
            type = str;
          };
        };

        syncthing.id = lib.mkOption {
          type = str;
        };
      };
    });
  };

  config = {
    _module.args.here = config.machines.${hostName};

    machines = {
      wo = {
        isServer = true;
        wireguard = {
          ipv4 = "10.42.0.1";
          ipv6 = "fd42::0:1";
          publicKey = "fzC/SGpGcIbH/DyHrPYIW+9aAm2h4CvHZZosBPEHDHA=";
        };
        syncthing.id = "7YQ7LRQ-IAWYNHN-VGHTAEQ-JDSH3C7-DUPWBYD-G6L4OJC-W3YLUFZ-SSM5CA6";
      };
      fu = {
        isStation = true;
        wireguard = {
          ipv4 = "10.42.1.1";
          ipv6 = "fd42::1:1";
          publicKey = "v1MDB6hEYKdBwdVN/rOnOGB82h3xTQpHwU3CAcctGWg=";
        };
        syncthing.id = "VVLGMST-LA633IY-KWESSFD-7FFF7LE-PNJAEML-ZXZSBLL-ATLQHPT-MUHEDAR";
      };
      mo = {
        isStation = true;
        wireguard = {
          ipv4 = "10.42.2.1";
          ipv6 = "fd42::2:1";
          publicKey = "tsvrIdHACcHMhtaHQt2tVE+2FO1LMdtiAlSXPNMuHFc=";
        };
        syncthing.id = "WO4GV6E-AJGKLLQ-M7RZGFT-WY7CCOW-LXODXRY-F3QPEJ2-AXDVWKR-SWBGDQP";
      };
      tsu = {
        wireguard = {
          ipv4 = "10.42.3.1";
          ipv6 = "fd42::3:1";
          publicKey = "fRJFAT9BrQW5Wis3Jxq3mTR66IF6YlhvcCtMmjm78kI=";
        };
        syncthing.id = "KXGLMP5-D2RKWZR-QUASDWC-T6H337M-HMEYLX7-D7EW4LM-UARXLZN-NXKVZAU";
      };
    };
  };
}
