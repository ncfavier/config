{ config, pkgs, lib, me, my, myHm, configPath, secretsPath, ... }: let
  relayPort = 6666;
  logsPath = "${my.home}/irc-logs";
  scripts = [
    "color_popup.pl"
    "highmon.pl"
    "perlexec.pl"
    "autojoin.py"
    "autosort.py"
    "buffer_autoset.py"
    "colorize_nicks.py"
    "go.py"
    "screen_away.py"
    "title.py"
  ];
in {
  system.activationScripts."linger-${me}" = lib.stringAfter [ "users" ] ''
    /run/current-system/systemd/bin/loginctl enable-linger ${me}
  '';

  sops.secrets.weechat-sec = {
    sopsFile = "${secretsPath}/weechat-sec";
    format = "binary";
    owner = me;
    inherit (my) group;
  };

  home-manager.users.${me} = { lib, ... }: {
    systemd.user.services.tmux-weechat = {
      Unit = {
        Description = "weechat in a tmux session";
        Wants = [ "network-online.target" ];
        After = [ "network-online.target" "network.target" ];
      };

      Install.WantedBy = [ "default.target" ];

      Service = let
        weechat = pkgs.weechat.override {
          configure = { availablePlugins, ... }: {
            plugins = with availablePlugins; [ python perl ];
            init = ''
              /set relay.port.weechat ${toString relayPort}
              /set logger.file.path ${logsPath}
              /script install ${builtins.concatStringsSep " " scripts}
            '';
          };
        };
        PATH = lib.replaceStrings [ "$USER" "$HOME" ] [ me my.home ]
          (lib.makeBinPath ([ weechat ] ++ config.environment.profiles));
      in {
        Type = "forking";
        Environment = "PATH=${PATH}";
        ExecStart     = "${pkgs.tmux}/bin/tmux -L weechat new-session -s weechat -d weechat";
        ExecStartPost = "${pkgs.tmux}/bin/tmux -L weechat set-option status off";
      };
    };

    home.file = let
      confs = map (f: "${f}.conf")
        [ "alias" "autosort" "buffer_autoset" "buflist" "charset" "colorize_nicks"
          "exec" "fifo" "fset" "irc" "logger" "perl" "plugins" "python" "relay"
          "script" "sec" "spell" "trigger" "weechat" "xfer" ];
    in lib.listToAttrs (map (file: {
      name = ".weechat/${file}";
      value.source = myHm.lib.file.mkOutOfStoreSymlink "${configPath}/profiles/weechat/config/${file}";
    }) confs);
  };

  networking.firewall.allowedTCPPorts = [ relayPort ];

  nixpkgs.overlays = [
    (self: super: {
      weechat-unwrapped = super.weechat-unwrapped.overrideAttrs (old: {
        patches = [
          (builtins.toFile "weechat-patch" ''
            diff --git a/src/core/weechat.c b/src/core/weechat.c
            index fd636979c..300926320 100644
            --- a/src/core/weechat.c
            +++ b/src/core/weechat.c
            @@ -695,7 +695,7 @@ weechat_locale_check ()
             void
             weechat_sighup ()
             {
            -    weechat_reload_signal = SIGHUP;
            +    weechat_quit_signal = SIGHUP;
             }

             /*
            diff --git a/src/plugins/exec/exec.c b/src/plugins/exec/exec.c
            index 5daf7ec83..7a0da49f5 100644
            --- a/src/plugins/exec/exec.c
            +++ b/src/plugins/exec/exec.c
            @@ -89,7 +89,7 @@ exec_search_by_id (const char *id)
                 error = NULL;
                 number = strtol (id, &error, 10);
                 if (!error || error[0])
            -        return NULL;
            +        number = -1;

                 for (ptr_exec_cmd = exec_cmds; ptr_exec_cmd;
                      ptr_exec_cmd = ptr_exec_cmd->next_cmd)
          '')
        ];
      });
    })
  ];
}
