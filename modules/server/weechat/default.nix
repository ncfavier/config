{ lib, here, config, secrets, syncedFolders, utils, pkgs, ... }: with lib; let
  relayPort = 6642;
  scripts = [
    "color_popup.pl"
    "highmon.pl"
    "perlexec.pl"
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
      scripts = with pkgs.weechatScripts; [ weechat-matrix ];
      init = "/exec -oc cat ${builtins.toFile "weechat-init" ''
        /script install ${concatStringsSep " " scripts}
        /script load ${./autojoin.py}
        /set sec.crypt.passphrase_command "cat ${secrets.weechat.path}"
        /set relay.network.bind_address ${here.wireguard.ipv4}
        /set relay.port.weechat ${toString relayPort}
        /set logger.file.path ${syncedFolders.irc-logs.path}
      ''}";
    };
  };
in {
  sops.secrets.weechat = {
    owner = my.username;
    inherit (config.my) group;
  };

  # TODO linger module
  system.activationScripts."linger-${my.username}" = stringAfter [ "users" ] ''
    /run/current-system/systemd/bin/loginctl enable-linger ${my.username}
  '';

  hm = {
    systemd.user.services.tmux-weechat = {
      Unit = {
        Description = "WeeChat in a tmux session";
        Wants = [ "network-online.target" ];
        After = [ "network-online.target" "nss-lookup.target" ];
        X-RestartIfChanged = false;
      };
      Service = {
        Type = "forking";
        ExecStart     = "${pkgs.tmux}/bin/tmux -L weechat new-session -s weechat -d ${config.my.shellPath} -lc 'exec ${weechat}/bin/weechat'";
        ExecStartPost = "${pkgs.tmux}/bin/tmux -L weechat set-option status off \\; set-option mouse off";
      };
      Install.WantedBy = [ "default.target" ];
    };

    home.file = mapAttrs' (name: _: {
      name = ".weechat/${name}";
      value.source = utils.mkMutableSymlink (./. + "/${name}");
    }) (filterAttrs (name: _: hasSuffix ".conf" name) (builtins.readDir ./.));
  };

  networking.firewall.allowedTCPPorts = [ relayPort ];
}
