{ config, pkgs, lib, me, my, secrets, syncedFolders, ... }: let
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
  ];
  weechat = pkgs.weechat.override {
    configure = { availablePlugins, ... }: {
      plugins = with availablePlugins; [ python perl ];
      init = ''
        /set sec.crypt.passphrase_file ${secrets.weechat-sec.path}
        /set relay.port.weechat ${toString relayPort}
        /set logger.file.path ${syncedFolders.irc-logs.path}
        /script install ${builtins.concatStringsSep " " scripts}
      '';
    };
  };
in {
  sops.secrets.weechat-sec = {
    owner = me;
    inherit (my) group;
  };

  systemd.services."tmux-weechat-${me}" = {
    description = "WeeChat in a tmux session";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "nss-lookup.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = me;
      Group = my.group;
      Type = "forking";
      ExecStart     = "${pkgs.tmux}/bin/tmux -L weechat new-session -s weechat -d ${my.shellPath} -lc 'exec ${weechat}/bin/weechat'";
      ExecStartPost = "${pkgs.tmux}/bin/tmux -L weechat set-option status off \\; set-option mouse off";
    };
    restartIfChanged = false;
  };

  myHm.home.file = lib.listToAttrs (map (name: {
    name = ".weechat/${name}.conf";
    value.source = config.myHm.lib.file.mkOutOfStoreSymlink "${my.mutableConfig}/profiles/weechat/config/${name}.conf";
  }) [
    "alias" "autosort" "buffer_autoset" "buflist" "charset" "colorize_nicks"
    "exec" "fifo" "fset" "irc" "logger" "perl" "plugins" "python" "relay"
    "script" "sec" "spell" "trigger" "weechat" "xfer"
  ]);

  networking.firewall.allowedTCPPorts = [ relayPort ];

  nixpkgs.overlays = [
    (self: super: {
      weechat-unwrapped = super.weechat-unwrapped.overrideAttrs ({ patches ? [], ... }: {
        patches = patches ++ [
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
