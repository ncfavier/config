lib: with lib; let
  modules = [
    (mkAliasOptionModule [ "server" ] [ "machines" "mu" ])
    {
      options.machines = mkOption {
        description = "My machines";
        type = with types; attrsOf (submodule ({ name, config, ... }: {
          freeformType = attrs;
          options = let
            mkMachineTypeOption = type: mkOption {
              description = "Whether the machine is a ${type}";
              type = bool;
              default = false;
            };
          in {
            hostname = mkOption {
              description = "The machine's hostname";
              type = str;
              default = name;
              readOnly = true;
            };
            isServer  = mkMachineTypeOption "server";
            isStation = mkMachineTypeOption "station";
            isPhone   = mkMachineTypeOption "phone";
            isISO = mkOption {
              type = bool;
              default = false;
            };
            ipv4 = mkOption {
              description = "The machine's public IPv4 addresses";
              type = listOf str;
              default = [];
            };
            ipv6 = mkOption {
              description = "The machine's public IPv6 addresses";
              type = listOf str;
              default = [];
            };
            sshPort = mkOption {
              description = "The machine's SSH port";
              type = nullOr int;
              default = null;
            };
            hasKVM = mkOption {
              description = "Whether the machine supports KVM.";
              type = bool;
              default = !config.isServer;
            };
          };
        }));
        default = {};
      };

      config = {
        _module.freeformType = with types; attrs;

        username = "n";
        githubUsername = "ncfavier";
        realName = "Naïm Favier";
        domain = "monade.li";
        email = "${my.username}@${my.domain}";
        pgpFingerprint = "F3EB4BBB4E7199BC299CD4E995AFCE8211908325";
        sshKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA9Kj3Zjnou6w4tZn60SAIYvrFlFQhSiKbLxTR9sVC1I ${my.email}"
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD7KZW1RCBXJY1uDLbmaDUm50eshkv1rT8eK0JJXR3MfuCaJ/Kqrg547ZjczxED98Qy8A7d1BrIsOiKEoFVou+jCcjU19hlkQiMce3IZmYm0h6MOmZqB0MR6EGTlAgDfkiDMYqnAUGst4p2xqqmH/gM/UI2d5ZFrxAbK+PC4d7yMxs5QJkJ0buXRnbKL/LGRWwyUCV8UDzQ26kYufVyAhS2Iz2SvUSqca5BaJOzAPJ74CFScbICFK5nlsc2kHH35ZqK3f1Jxmbpi8ZwXUyxT+pFUClzY/s5H4w8c70ItvOyD3T0B+a8MF2Ft/c1kLFnHfYJd2FET+RZJQ5P+kXW+iZb ${my.email}"
        ];

        machines = {
          mu = {
            isServer = true;
            ipv4 = [ "46.38.232.212" ];
            ipv6 = [ "2a03:4000:2:fd1::42" ];
            sshPort = 2242;
            wireguard = {
              ipv4 = "10.42.0.1";
              ipv6 = "fd42::0:1";
              publicKey = "wYNBfzEDs9E10z/wfeWuOe6u63SFW+7EWdGHYrU1SUc=";
            };
            syncthing.id = "26Z2VZW-TJEASC6-CWQHMCJ-QMGT4MJ-YTTUW7V-M6IIUQU-LY3SCYS-UQ6FGAY";
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
          no = {
            isStation = true;
            wireguard = {
              ipv4 = "10.42.2.2";
              ipv6 = "fd42::2:2";
              publicKey = "mQe4b0adN/BDQUTAzc+0rZp8M+ZjV17ewEtBLRIdM0I=";
            };
            syncthing.id = "MN3PICD-LGLVMZ2-SSNK5CG-LXNWL5R-U2QMWNM-AIA4UAG-NQ5WT5Y-B3TKXQV";
          };
          tsu = {
            isPhone = true;
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
  ];
in (evalModules { inherit modules; }).config
