{ inputs, lib, config, ... }: with lib; {
  imports = [ inputs.sops-nix.nixosModule ];

  options.sops.secrets = mkOption {
    type = with types; attrsOf (submodule ({ config, name, ... }: {
      sopsFile = "${inputs.self}/secrets/${name}" +
        optionalString (config.format != "binary") ".${config.format}";
    }));
  };

  config = {
    _module.args.secrets = config.sops.secrets;

    sops = {
      gnupgHome = "${config.my.home}/.gnupg";
      sshKeyPaths = [];
      defaultSopsFormat = "binary";
    };
  };
}
