{ config, pkgs, lib, me, my, myHm, configPath, secretsPath, ... }: let
  relayPort = 6600;
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
    "tmux_env.py"
  ];
  weechat = pkgs.weechat.override {
    configure = { availablePlugins, ... }: {
      plugins = with availablePlugins; [ python perl ];
      init = ''
        /set relay.port.weechat ${toString relayPort}
        /set logger.file.path ${config.services.syncthing.declarative.folders.irc-logs.path}
        /script install ${builtins.concatStringsSep " " scripts}
      '';
    };
  };
in {
  system.activationScripts."linger-${me}" = lib.stringAfter [ "users" ] ''
    /run/current-system/systemd/bin/loginctl enable-linger ${me}
  ''; # TODO linger module

  sops.secrets.weechat-sec = {
    sopsFile = secretsPath + "/weechat-sec";
    format = "binary";
    owner = me;
    inherit (my) group;
  };

  home-manager.users.${me} = { lib, ... }: {
    systemd.user.services.tmux-weechat = {
      Unit = {
        Description = "weechat in a tmux session";
        Wants = [ "import-environment.service" "network-online.target" ];
        After = [ "import-environment.service" "network-online.target" "network.target" ];
      };

      Install.WantedBy = [ "default.target" ];

      Service = {
        Type = "forking";
        ExecStart     = "${pkgs.tmux}/bin/tmux -L weechat new-session -s weechat -d ${weechat}/bin/weechat";
        ExecStartPost = "${pkgs.tmux}/bin/tmux -L weechat set-option status off \\; set-option mouse off";
      };
    };

    home.file = lib.listToAttrs (map (name: {
      name = ".weechat/${name}.conf";
      value.source = myHm.lib.file.mkOutOfStoreSymlink "${configPath}/profiles/weechat/config/${name}.conf";
    }) [
      "alias" "autosort" "buffer_autoset" "buflist" "charset" "colorize_nicks"
      "exec" "fifo" "fset" "irc" "logger" "perl" "plugins" "python" "relay"
      "script" "sec" "spell" "trigger" "weechat" "xfer"
    ]);
  };

  networking.firewall.allowedTCPPorts = [ relayPort ];

  nixpkgs.overlays = [
    (self: super: {
      weechat-unwrapped = super.weechat-unwrapped.overrideAttrs (old: {
        patches = old.patches or [] ++ [
          (builtins.toFile "weechat-patch" ''
            Avoid reloading configuration on SIGHUP (https://github.com/weechat/weechat/issues/1595)
            --- a/src/core/weechat.c
            +++ b/src/core/weechat.c
            @@ -698 +698 @@ weechat_sighup ()
            -    weechat_reload_signal = SIGHUP;
            +    weechat_quit_signal = SIGHUP;
          '')
        ];
      });
    })
  ];
}
