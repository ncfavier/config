{ inputs, lib, config, utils, ... }: with lib; {
  imports = [ (mkAliasOptionModule [ "my" ] [ "users" "users" my.username ]) ];

  options.users.users = mkOption {
    type = with types; attrsOf (submodule ({ config, ... }: {
      options.shellPath = mkOption {
        type = str;
        default = utils.toShellPath config.shell;
        defaultText = literalExpression "utils.toShellPath shell";
        readOnly = true;
      };
    }));
  };

  config = {
    users = {
      users = {
        ${my.username} = {
          uid = 1000;
          isNormalUser = true;
          description = my.realName;
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = my.sshKeys;
        };

        root = {
          inherit (config.my) hashedPassword;
          openssh.authorizedKeys.keys = config.my.openssh.authorizedKeys.keys;
        };
      };
    };

    hm.home.file.".hushlogin".text = "";

    security = {
      sudo = {
        wheelNeedsPassword = false;
        extraConfig = ''
          Defaults env_keep+="EDITOR"
          Defaults env_keep+="SSH_CONNECTION SSH_CLIENT SSH_TTY"
        '';
      };

      polkit.extraConfig = ''
        polkit.addRule(function (action, subject) {
          if (subject.isInGroup('wheel'))
            return polkit.Result.YES;
        });
      '';
    };

    boot.kernel.sysctl."kernel.dmesg_restrict" = false;
  };
}
