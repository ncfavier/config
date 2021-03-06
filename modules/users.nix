{ inputs, lib, config, utils, ... }: with lib; {
  imports = [ (mkAliasOptionModule [ "my" ] [ "users" "users" my.username ]) ];

  options.users.users = mkOption {
    type = with types; attrsOf (submodule ({ config, ... }: {
      options.shellPath = mkOption {
        type = str;
        default = utils.toShellPath config.shell;
        readOnly = true;
      };
    }));
  };

  config = {
    users = {
      mutableUsers = false;

      users = {
        ${my.username} = {
          isNormalUser = true;
          description = my.realName;
          extraGroups = [ "wheel" "audio" "video" ];
          openssh.authorizedKeys.keys = [
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD7KZW1RCBXJY1uDLbmaDUm50eshkv1rT8eK0JJXR3MfuCaJ/Kqrg547ZjczxED98Qy8A7d1BrIsOiKEoFVou+jCcjU19hlkQiMce3IZmYm0h6MOmZqB0MR6EGTlAgDfkiDMYqnAUGst4p2xqqmH/gM/UI2d5ZFrxAbK+PC4d7yMxs5QJkJ0buXRnbKL/LGRWwyUCV8UDzQ26kYufVyAhS2Iz2SvUSqca5BaJOzAPJ74CFScbICFK5nlsc2kHH35ZqK3f1Jxmbpi8ZwXUyxT+pFUClzY/s5H4w8c70ItvOyD3T0B+a8MF2Ft/c1kLFnHfYJd2FET+RZJQ5P+kXW+iZb ${my.email}"
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDXcKmcpfziEqVXmhYIJyZ03DOb5x7wcf+FxYUWewWeBS5g1MfWKw/FH1H0EQeJf6z0epc/0oN50AViqe1zBnUChGGF2xjNzGEpDPjHg0MuEDMboXBHDBbBRjb31S4T7pkZ72cCV06+bilWdYnXc0E7ND81BakmuBJHFH3DvjYXudFdhwLEtmXAVIOdLBlIStY6ZMkHojPOjnfYrREa7PfllrH0dqwQI/v1dU7E6ZHV5OK631HhcAFhySlu4jdo890czsEqwTkMSrPrgVXiiQipvFAavZvqB53d9J36BkSeVO3meqz2x9N6puXL1A/f+a2Suc5mfMUayFm35lE3sw1h tsu"
          ];
        };

        root = {
          inherit (config.my) hashedPassword;
          openssh.authorizedKeys.keys = config.my.openssh.authorizedKeys.keys;
        };
      };
    };

    hm.home.file.".hushlogin".text = "";
  };
}
