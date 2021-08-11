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
          openssh.authorizedKeys.keys = my.sshKeys;
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
