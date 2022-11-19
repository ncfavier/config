{ inputs, lib, config, pkgs, ... }: with lib; let
  cfg = config.services.bothendieck;
  settingsFormat = pkgs.formats.toml {};
in {
  options.services.bothendieck = {
    enable = mkEnableOption "bothendieck" // { default = true; };
    settings = mkOption {
      type = types.submodule {
        freeformType = settingsFormat.type;
      };
      default = {};
    };
    secretsFile = mkOption {
      type = with types; nullOr path;
      default = null;
      description = "File containing extra configuration (secrets).";
    };
  };

  config = mkIf cfg.enable {
    system.extraDependencies = collectFlakeInputs inputs.bothendieck;

    secrets.bothendieck = {};

    systemd.services.bothendieck = let
      bothendieck = inputs.bothendieck.packages.${pkgs.system}.bothendieck.override {
        evaluators = ((inputs.bothendieck.inputs.qeval.legacyPackages.${pkgs.system}.override {
          baseKernelPackages = pkgs.linuxPackages_latest;
          qemu = pkgs.qemu_kvm;
          enableKVM = false;
          suspensionUseCompression = false; # favour speed
          timeout = 30;
        }).evaluators.override {
          filterEvaluators = all: builtins.removeAttrs all [ "java" "kotlin" ];
        }).all;
      };
      configFile = settingsFormat.generate "bothendieck.toml" cfg.settings;
    in {
      description = "bothendieck";
      after = [ "network.target" "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        DynamicUser = true;
        LoadCredential = mkIf (cfg.secretsFile != null) "secrets:${cfg.secretsFile}";
        ExecStart = "${bothendieck}/bin/bothendieck --config ${configFile} ${lib.optionalString (cfg.secretsFile != null) "--extra-config \${CREDENTIALS_DIRECTORY}/secrets"}";

        DevicePolicy = "closed";
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "full";
        RemoveIPC = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_NETLINK" "AF_UNIX" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
      };
    };

    services.bothendieck = {
      settings = {
        server = "irc.libera.chat";
        tls = true;
        port = 6697;
        nick = "|||";
        realName = "bothendieck";
        channels = [ "##nf" ];
        commandPrefix = ".";
      };
      secretsFile = config.secrets.bothendieck.path;
    };
  };
}
