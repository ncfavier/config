{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (haskellPackages.ghcWithHoogle (p: with p; [
      adjunctions
      arithmoi
      array
      comonad
      containers
      kan-extensions
      lens
      linear
      megaparsec
      mtl
      profunctors
      random
      split
      vector
    ]))
  ];

  hm.home.file = {
    ".ghc/ghci.conf".text = ''
      :set prompt      "> "
      :set prompt-cont "| "
      :set +t
      :m + Control.Applicative Control.Arrow Control.Monad Data.Bifunctor Data.Bool Data.Char Data.Complex Data.Either Data.Foldable Data.Function Data.Functor Data.Functor.Identity Data.List Data.Maybe Data.Monoid Data.Ratio Data.Semigroup Data.String Data.Traversable Data.Tuple Data.Void System.IO System.Exit System.Environment System.Random Text.Read
      :def hoogle \x -> pure $ ":!hoogle search \"" ++ x ++ "\""
    '';

    ".haskeline".text = ''
      bind: up meta-k
      bind: down meta-j
      maxhistorysize: Just 5000
    '';
  };
}
