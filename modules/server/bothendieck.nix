{ inputs, this, lib, config, pkgs, ... }: with lib; let
  cfg = config.services.bothendieck;

  settingsFormat = pkgs.formats.toml {};
  configFile = settingsFormat.generate "bothendieck.toml" cfg.settings;

  bothendieck = inputs.bothendieck.packages.${pkgs.system}.bothendieckWithEvaluators.override (old: {
    qeval = old.qeval.override ({ pkgs, ... }: {
      baseKernelPackages = pkgs.linuxPackages_latest;
      enableKVM = this.hasKVM;
      qemu = pkgs.qemu_kvm; # don't rebuild QEMU
      suspensionUseCompression = false; # favour speed
      suspensionTimeout = 300;
      editEvaluators = evs: builtins.removeAttrs evs [
        "java" "kotlin" # too slow
        "python2" # EOL, don't feel like compiling it
      ] // {
        rust = lib.recursiveUpdate evs.rust {
          storeDrives.rust = with pkgs; [ rustc gcc ]; # don't use the nightly channel
        };

        haskell = evs.haskell.override {
          packages = (p: with p; [
            adjunctions
            containers
            kan-extensions
            random
            NumInstances
          ]);
          init = ''
            :set -XBangPatterns
            :set -XBlockArguments
            :set -XEmptyCase
            :set -XImportQualifiedPost
            :set -XLambdaCase
            :set -XNamedFieldPuns
            :set -XNegativeLiterals
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
            import Control.Concurrent
            import Control.Monad
            import Control.Monad.Codensity
            import Data.Bifunctor
            import Data.Char
            import Data.Complex
            import Data.Either
            import Data.Foldable
            import Data.Function
            import Data.Functor
            import Data.Functor.Adjunction
            import Data.Functor.Day
            import Data.Functor.Identity
            import Data.Functor.Yoneda
            import Data.Functor.Coyoneda
            import Data.Ix
            import Data.List
            import Data.Map (Map)
            import Data.Map qualified as Map
            import Data.Maybe
            import Data.Monoid
            import Data.NumInstances
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
            import System.Random
          '';
        };
      };
    });
  });
in {
  options.services.bothendieck = {
    enable = mkEnableOption "bothendieck";
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
    lib = { inherit bothendieck; };

    system.extraDependencies = collectFlakeInputs inputs.bothendieck ++ collectFlakeInputs inputs.qeval ++ [ bothendieck.cabal2nixDeriver pkgs.nur.repo-sources.tilpner ];

    secrets.bothendieck = {};

    systemd.services.bothendieck = {
      description = "bothendieck";
      after = [ "network.target" "network-online.target" "nss-lookup.target" ];
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

        Restart = "on-failure";
        RestartSec = "10s";
      };
      unitConfig = {
        StartLimitIntervalSec = "1min";
        StartLimitBurst = 5;
      };
    };

    services.bothendieck = {
      settings = {
        server = "irc.eu.libera.chat";
        tls = true;
        port = 6697;
        nick = "|||";
        realName = "bothendieck";
        channels = [ "##nf" "#tendra" ];
        commandPrefix = ".";
        pasteUrl = "https://f.${my.domain}";
        pasteField = "file";
        urlAlternativeHosts = fix (self: {
          "youtube.com" = "https://yewtu.be";
          "www.youtube.com" = self."youtube.com";
          "youtu.be" = self."youtube.com" + "/watch";
          "x.com" = "https://nitter.privacydev.net";
          "xcancel.com" = self."x.com";
          "twitter.com" = self."x.com";
          "m.twitter.com" = self."x.com";
          "reddit.com" = "https://libreddit.nl";
          "www.reddit.com" = self."reddit.com";
          "old.reddit.com" = self."reddit.com";
        });
      };
      secretsFile = config.secrets.bothendieck.path;
    };

    # services.nitter = {
    #   enable = true;
    #   package = pkgs.nitter.overrideAttrs (o: {
    #     src = pkgs.fetchFromGitHub {
    #       owner = "zedeus";
    #       repo = "nitter";
    #       rev = "b62d73dbd373f08af07c7a79efcd790d3bc1a49c";
    #       hash = "sha256-yCD7FbqWZMY0fyFf9Q3Ka06nw5Ha7jYLpmPONAhEVIM=";
    #     };
    #   });
    #   openFirewall = false;
    #   server.hostname = my.domain;
    #   server.address = head this.ipv4; # can't use a local address because bothendieck blocks those
    #   server.port = 8099;
    #   # server.httpMaxConnections = 2;
    #   # config.tokenCount = 1;
    #   # cache.redisConnections = 1;
    # };
  };
}
