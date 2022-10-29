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
    passwordFile = mkOption {
      type = with types; nullOr path;
      default = null;
      description = "File containing the NickServ password to use.";
    };
  };

  config = mkIf cfg.enable {
    system.extraDependencies = collectFlakeInputs inputs.bothendieck;

    secrets.bothendieck = {};

    systemd.services.bothendieck = let
      bothendieck = inputs.bothendieck.packages.${pkgs.system}.bothendieck.override {
        evaluators = ((inputs.bothendieck.inputs.qeval.legacyPackages.${pkgs.system}.override {
          baseKernelPackages = pkgs.linuxPackages_latest;
          enableKVM = false;
          suspensionUseCompression = false; # favour speed
          timeout = 30;
        }).evaluators.override {
          filterEvaluators = all: builtins.removeAttrs all [ "kotlin" ];
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
        LoadCredential = mkIf (cfg.passwordFile != null) "password:${cfg.passwordFile}";
        ExecStart = "${bothendieck}/bin/bothendieck --config ${configFile} ${lib.optionalString (cfg.passwordFile != null) "--password-file \${CREDENTIALS_DIRECTORY}/password"}";

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
      passwordFile = config.secrets.bothendieck.path;
    };
  };
}
