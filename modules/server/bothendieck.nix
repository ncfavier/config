{ inputs, this, lib, config, pkgs, ... }: with lib; let
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
      bothendieck = inputs.bothendieck.packages.${pkgs.system}.bothendieck.override (old: {
        qeval = old.qeval.override {
          baseKernelPackages = pkgs.linuxPackages_latest;
          enableKVM = this.hasKVM;
          qemu = pkgs.qemu_kvm; # don't rebuild QEMU
          suspensionUseCompression = false; # favour speed
          editEvaluators = evs: builtins.removeAttrs evs [ "java" "kotlin" ] // {
            rust = lib.recursiveUpdate evs.rust {
              storeDrives.rust = with pkgs; [ rustc gcc ]; # don't use the nightly channel
            };

            haskell = evs.haskell.override {
              packages = (p: with p; [
                adjunctions
                containers
                kan-extensions
                lens
                split
              ]);
              init = ''
                :set -XBangPatterns
                :set -XBlockArguments
                :set -XEmptyCase
                :set -XImportQualifiedPost
                :set -XLambdaCase
                :set -XNamedFieldPuns
                :set -XNumericUnderscores
                :set -XOverloadedStrings
                :set -XRankNTypes
                :set -XRecordWildCards
                :set -XRecursiveDo
                :set -XScopedTypeVariables
                :set -XTupleSections
                :set -XTypeApplications
                :set -XUnicodeSyntax
                :set -XViewPatterns
                import Control.Applicative
                import Control.Arrow
                import Control.Lens
                import Control.Monad
                import Data.Bifunctor
                import Data.Char
                import Data.Complex
                import Data.Either
                import Data.Foldable
                import Data.Function
                import Data.Functor
                import Data.Functor.Identity
                import Data.Ix
                import Data.List
                import Data.Map (Map)
                import Data.Map qualified as Map
                import Data.Maybe
                import Data.Monoid
                import Data.Ord
                import Data.Ratio
                import Data.Semigroup
                import Data.Set (Set)
                import Data.Set qualified as Set
                import Data.String
                import Data.Traversable
                import Data.Tuple
                import Data.Void
                import System.Environment
                import System.Exit
                import System.IO
              '';
            };
          };
        };
      });
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
