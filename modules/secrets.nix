{ inputs, lib, this, config, pkgs, ... }: with lib; {
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

      # GPG running as root can't find my socket dir (https://github.com/NixOS/nixpkgs/issues/57779)
      environment.SOPS_GPG_EXEC = pkgs.writeShellScript "gpg-${my.username}" ''
        exec ${pkgs.util-linux}/bin/runuser -u ${my.username} -- ${pkgs.gnupg}/bin/gpg "$@"
      '';

      secrets = let
        secretsDir = "${inputs.self}/secrets";
      in mapAttrs' (name: _: let
        parts = splitString "." name;
        base = head parts;
        format = if length parts > 1 then elemAt parts 1 else "binary";
      in nameValuePair base {
        sopsFile = "${secretsDir}/${name}";
        inherit format;
        key = this.hostname;
      }) (builtins.readDir secretsDir);
    };

    environment = {
      systemPackages = [ pkgs.sops ];
      sessionVariables.SOPS_PGP_FP = my.pgpFingerprint;
    };

    hm.programs.password-store.enable = true;

    nix.settings = {
      substituters = mkAfter [ "https://mic92.cachix.org" ];
      trusted-public-keys = mkAfter [ "mic92.cachix.org-1:gi8IhgiT3CYZnJsaW7fxznzTkMUOn1RY4GmXdT/nXYQ=" ];
    };

    system.extraDependencies = [ inputs.sops-nix ];
  };
}
