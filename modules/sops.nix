{ inputs, config, pkgs, lib, my, ... }: {
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.sops.secrets = lib.mkOption {
    type = with lib.types; attrsOf (submodule ({ config, name, ... }: {
      sopsFile = "${inputs.self}/secrets/${name}" +
        lib.optionalString (config.format != "binary") ".${config.format}";
    }));
  };

  config = {
    _module.args.secrets = config.sops.secrets;

    sops = {
      gnupgHome = "${my.home}/.gnupg";
      sshKeyPaths = [];
      defaultSopsFormat = "binary";
    };

    environment = { # TODO move this to devShell
      systemPackages = [ pkgs.sops ];
      variables.SOPS_PGP_FP = my.pgpFingerprint;
    };
  };
}
