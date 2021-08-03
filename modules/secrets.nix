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
      gnupgHome = "${config.my.home}/.gnupg";
      sshKeyPaths = [];
      defaultSopsFormat = "binary";
    };

    environment = {
      systemPackages = [ pkgs.sops ];
      sessionVariables.SOPS_PGP_FP = my.pgpFingerprint;
    };
  };
}
