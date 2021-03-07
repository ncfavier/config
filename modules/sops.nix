{ inputs, config, pkgs, lib, my, ... }: {
  imports = [ inputs.sops-nix.nixosModule ];

  options.sops.secrets = lib.mkOption {
    type = with lib.types; attrsOf (submodule ({ config, name, ... }: {
      sopsFile = "${inputs.self}/secrets/${name}" +
        lib.optionalString (config.format != "binary") ".${config.format}";
    }));
  };

  config = {
    _module.args.secrets = config.sops.secrets;

    sops = {
      gnupgHome = "${config.my.home}/.gnupg";
      sshKeyPaths = [];
      defaultSopsFormat = "binary";
    };

    system.activationScripts.secrets-permissions = lib.stringAfter [ "setup-secrets" ] ''
      chmod o+x /run/secrets /run/secrets.d
    '';
  };
}
