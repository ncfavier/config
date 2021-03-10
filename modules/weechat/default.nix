{ config, pkgs, lib, here, secrets, my, syncedFolders, ... }: let
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
      init = "/exec -oc cat ${builtins.toFile "weechat-init" ''
        /set sec.crypt.passphrase_file ${secrets.weechat-sec.path}
        /set relay.network.bind_address ${here.wireguard.ipv6}
        /set relay.port.weechat ${toString relayPort}
        /set logger.file.path ${syncedFolders.irc-logs.path}
        /script install ${builtins.concatStringsSep " " scripts}
      ''}";
    };
  };
in {
  config = lib.mkIf here.isServer {
    sops.secrets.weechat-sec = {
      owner = my.username;
      inherit (config.my) group;
    };

    systemd.services."tmux-weechat-${my.username}" = {
      description = "WeeChat in a tmux session";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" "nss-lookup.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = my.username;
        Group = config.my.group;
        Type = "forking";
        ExecStart     = "${pkgs.tmux}/bin/tmux -L weechat new-session -s weechat -d ${config.my.shellPath} -lc 'exec ${weechat}/bin/weechat'";
        ExecStartPost = "${pkgs.tmux}/bin/tmux -L weechat set-option status off \\; set-option mouse off";
      };
      restartIfChanged = false;
    };

    myHm.home.file = lib.listToAttrs (map (name: {
      name = ".weechat/${name}.conf";
      value.source = config.lib.meta.mkMutableSymlink (./config + "/${name}.conf");
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
  };
}
