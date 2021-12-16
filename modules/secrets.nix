{ inputs, lib, here, config, pkgs, ... }: with lib; {
  imports = [
    inputs.sops-nix.nixosModule
    (mkAliasOptionModule [ "secrets" ] [ "sops" "secrets" ])
  ];

  config = {
    sops = {
      gnupg = {
        home = config.hm.programs.gpg.homedir;
        sshKeyPaths = [];
      };

      secrets = let
        secretsDir = "${inputs.self}/secrets";
      in mapAttrs' (name: _: let
        parts = splitString "." name;
        base = head parts;
        format = if length parts > 1 then elemAt parts 1 else "binary";
      in nameValuePair base {
        sopsFile = "${secretsDir}/${name}";
        inherit format;
        key = here.hostname;
      }) (builtins.readDir secretsDir);
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
