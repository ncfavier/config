{ lib, config, pkgs, ... }: with lib; {
  # TODO declare imported modules (override Pristine.hs.default)
  secrets.lambdabot-ulminfo = {
    owner = config.users.users.lambdabot.name;
    group = config.users.users.lambdabot.group;
  };

  services.lambdabot = {
    enable = true;
    package = let
      packages = [
        "adjunctions"
        "arithmoi"
        "array"
        "comonad"
        "containers"
        "kan-extensions"
        "lens"
        "linear"
        "megaparsec"
        "mtl"
        "profunctors"
        "split"
        "unordered-containers"
        "vector"
      ];
    in pkgs.lambdabot.override {
      packages = attrVals packages;
      configuration = ''[
        textWidth ==> 380,
        commandPrefixes ==> ["@"],
        evalPrefixes ==> ["%"],
        trustedPackages ==> [
          "base",
          "bifunctors",
          "bytestring",
          "ghc-prim",
          "lambdabot-trusted",
          "random",
          "semigroupoids",
          "text",
          ${concatMapStringsSep ", " (p: ''"${pkgs.haskellPackages.${p}.pname or p}"'') packages}
        ],
        languageExts ==> [
          "Arrows",
          "BangPatterns",
          "BinaryLiterals",
          "BlockArguments",
          "ConstrainedClassMethods",
          "ConstraintKinds",
          "DataKinds",
          "DeriveDataTypeable",
          "DeriveFoldable",
          "DeriveFunctor",
          "DeriveGeneric",
          "DeriveLift",
          "DeriveTraversable",
          "DerivingVia",
          "DoAndIfThenElse",
          "EmptyCase",
          "EmptyDataDecls",
          "EmptyDataDeriving",
          "ExistentialQuantification",
          "ExplicitForAll",
          "ExtendedDefaultRules",
          "FlexibleContexts",
          "FlexibleInstances",
          "GADTs",
          "GeneralisedNewtypeDeriving",
          "HexFloatLiterals",
          "ImplicitPrelude",
          "ImportQualifiedPost",
          "InstanceSigs",
          "KindSignatures",
          "LambdaCase",
          "LiberalTypeSynonyms",
          "LinearTypes",
          "MonadComprehensions",
          "MultiParamTypeClasses",
          "MultiWayIf",
          "NamedFieldPuns",
          "NamedWildCards",
          "NoMonomorphismRestriction",
          "NumericUnderscores",
          "OverloadedStrings",
          "PartialTypeSignatures",
          "PatternGuards",
          "PatternSynonyms",
          "PolyKinds",
          "PostfixOperators",
          "RankNTypes",
          "RecordWildCards",
          "RecursiveDo",
          "RelaxedPolyRec",
          "ScopedTypeVariables",
          "StandaloneDeriving",
          "StandaloneKindSignatures",
          "StarIsType",
          "TraditionalRecordSyntax",
          "TupleSections",
          "TypeApplications",
          "TypeOperators",
          "TypeFamilies",
          "TypeSynonymInstances",
          "UnicodeSyntax",
          "ViewPatterns"
        ]
      ]'';
    };
    script = ''
      irc-persist-connect ulminfo ens.wtf 6667 lambdabot lambdabot
      irc-persist-connect libera irc.eu.libera.chat 6667 haskell lambdabot
      rc ${config.secrets.lambdabot-ulminfo.path}
      admin + ulminfo:nf
      admin + libera:nf
      join ulminfo:#haskell
      join libera:##nf
    '';
  };

  systemd.services.lambdabot = {
    wants = [ "nss-lookup.target" ];
    after = [ "nss-lookup.target" ];
    serviceConfig = {
      MemoryMax = "10%";
      Restart = "on-failure";
    };
  };

  my.extraGroups = [ "lambdabot" ];

  nixpkgs.overlays = [ (pkgs: prev: let
    lambdabot = pkgs.fetchFromGitHub {
      owner = "ncfavier";
      repo = "lambdabot";
      rev = "live";
      sha256 = "sha256-ZH9sqHsIwd5MjXAzkeU85nAqhIbTn7x9RqQb9N/vYcI=";
    };
  in {
    haskell = prev.haskell // {
      packageOverrides = hpkgs: hprev: {
        lambdabot-core = hprev.lambdabot-core.overrideAttrs (_: { src = "${lambdabot}/lambdabot-core"; });
        lambdabot-reference-plugins = hpkgs.callCabal2nix "lambdabot-reference-plugins" "${lambdabot}/lambdabot-reference-plugins" {};
      };
    };
  }) ];
}
