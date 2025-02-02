lib: machines: with lib; let
  mainServer = "mu";

  modules = [
    (mkAliasOptionModule [ "server" ] [ "machines" mainServer ])
    ({ config, ... }: {
      freeformType = types.attrs;

      options.machines = mkOption {
        description = "My machines";
        type = with types; attrsOf (submodule ./identity.nix);
        default = {};
      };

      config = {
        username = "n";
        githubUsername = "ncfavier";
        chalmersId = "naimf";
        realName = "Naïm Favier";
        domain = "monade.li";
        email = "${my.username}@${my.domain}";
        pgpFingerprint = "F3EB4BBB4E7199BC299CD4E995AFCE8211908325";
        sshKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMy4X7ieNZEbVQQtz4PpWWv5bBeG0a7cXp74RjRRoTNX ${my.email}" # SSH
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA9Kj3Zjnou6w4tZn60SAIYvrFlFQhSiKbLxTR9sVC1I ${my.email}" # GPG
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD7KZW1RCBXJY1uDLbmaDUm50eshkv1rT8eK0JJXR3MfuCaJ/Kqrg547ZjczxED98Qy8A7d1BrIsOiKEoFVou+jCcjU19hlkQiMce3IZmYm0h6MOmZqB0MR6EGTlAgDfkiDMYqnAUGst4p2xqqmH/gM/UI2d5ZFrxAbK+PC4d7yMxs5QJkJ0buXRnbKL/LGRWwyUCV8UDzQ26kYufVyAhS2Iz2SvUSqca5BaJOzAPJ74CFScbICFK5nlsc2kHH35ZqK3f1Jxmbpi8ZwXUyxT+pFUClzY/s5H4w8c70ItvOyD3T0B+a8MF2Ft/c1kLFnHfYJd2FET+RZJQ5P+kXW+iZb ${my.email}" # GPG
        ];
        gravatar = "https://www.gravatar.com/avatar/1fea7494d69948ab0a50d9ee9318ae50";

        machines = catAttrs' "identity" machines;
        machinesWith = key: filterAttrs (_: v: v ? ${key} && v.${key} != null) config.machines;
        machinesThat = pred: filterAttrs (_: pred) config.machines;
        inherit mainServer;
      };
    })
  ];
in (evalModules { inherit modules; }).config
