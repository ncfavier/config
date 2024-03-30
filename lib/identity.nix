{ lib, name, config, ... }: with lib; with types; {
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
      type = nullOr str;
      default = name;
    };
    isServer  = mkMachineTypeOption "server";
    isStation = mkMachineTypeOption "station";
    isPhone   = mkMachineTypeOption "phone";
    isISO = mkOption {
      description = "Whether this is an ISO image";
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
}
