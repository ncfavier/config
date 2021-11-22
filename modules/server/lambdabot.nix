{ lib, config, pkgs, ... }: with lib; {
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
        "lens_5_0_1"
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
        commandPrefixes ==> ["@"],
        evalPrefixes ==> [],
        trustedPackages ==> [
          "base",
          "bifunctors",
          "bytestring",
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
          "DeriveTraversable",
          "DerivingVia",
          "EmptyCase",
          "EmptyDataDecls",
          "FlexibleContexts",
          "FlexibleInstances",
          "GADTs",
          "GeneralisedNewtypeDeriving",
          "ImportQualifiedPost",
          "LambdaCase",
          "LiberalTypeSynonyms",
          "MonadComprehensions",
          "MultiWayIf",
          "NamedFieldPuns",
          "NumericUnderscores",
          "OverloadedStrings",
          "PatternSynonyms",
          "PolyKinds",
          "RankNTypes",
          "RecordWildCards",
          "RecursiveDo",
          "ScopedTypeVariables",
          "StandaloneDeriving",
          "TupleSections",
          "TypeApplications",
          "TypeOperators",
          "UnicodeSyntax",
          "ViewPatterns",
          "BangPatterns",
          "BinaryLiterals",
          "ConstrainedClassMethods",
          "ConstraintKinds",
          "DeriveDataTypeable",
          "DeriveFoldable",
          "DeriveFunctor",
          "DeriveGeneric",
          "DeriveLift",
          "DeriveTraversable",
          "DoAndIfThenElse",
          "EmptyCase",
          "EmptyDataDecls",
          "EmptyDataDeriving",
          "ExistentialQuantification",
          "ExplicitForAll",
          "FlexibleContexts",
          "FlexibleInstances",
          "GADTSyntax",
          "GeneralisedNewtypeDeriving",
          "HexFloatLiterals",
          "ImplicitPrelude",
          "ImportQualifiedPost",
          "InstanceSigs",
          "KindSignatures",
          "MultiParamTypeClasses",
          "NamedFieldPuns",
          "NamedWildCards",
          "NoMonomorphismRestriction",
          "NumericUnderscores",
          "PatternGuards",
          "PolyKinds",
          "PostfixOperators",
          "RankNTypes",
          "RelaxedPolyRec",
          "ScopedTypeVariables",
          "StandaloneDeriving",
          "StandaloneKindSignatures",
          "StarIsType",
          "TraditionalRecordSyntax",
          "TupleSections",
          "TypeApplications",
          "TypeOperators",
          "TypeSynonymInstances"
        ]
      ]'';
    };
    script = ''
      irc-persist-connect ulminfo ens.wtf 6667 lambdabot lambdabot
      irc-persist-connect libera irc.libera.chat 6667 haskell lambdabot
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
  };
}
