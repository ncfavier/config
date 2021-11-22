{ inputs, lib, config, pkgs, ... }: with lib; {
  imports = [
    inputs.sops-nix.nixosModule
    (mkAliasOptionModule [ "secrets" ] [ "sops" "secrets" ])
  ];

  options.sops.secrets = mkOption {
    type = with types; attrsOf (submodule ({ config, name, ... }: {
      sopsFile = "${inputs.self}/secrets/${name}" +
        optionalString (config.format != "binary") ".${config.format}";
    }));
  };

  config = {
    sops = {
      gnupg = {
        home = config.hm.programs.gpg.homedir;
        sshKeyPaths = [];
      };
      defaultSopsFormat = "binary";
    };

    environment = {
      systemPackages = [ pkgs.sops ];
      sessionVariables.SOPS_PGP_FP = my.pgpFingerprint;
    };

    hm.programs.password-store.enable = true;

    nix = {
      binaryCaches = mkAfter [ "https://mic92.cachix.org" ];
      binaryCachePublicKeys = mkAfter [ "mic92.cachix.org-1:gi8IhgiT3CYZnJsaW7fxznzTkMUOn1RY4GmXdT/nXYQ=" ];
      gcRoots = [ inputs.sops-nix ];
    };
  };
}
