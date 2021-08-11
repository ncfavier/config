{ lib, here, config, utils, pkgs, ... }: with lib; let
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
        /set sec.crypt.passphrase_command "cat ${config.secrets.weechat.path}"
        /set relay.network.bind_address ${here.wireguard.ipv4}
        /set relay.port.weechat ${toString relayPort}
        /set logger.file.path ${config.synced.irc-logs.path}
      ''}";
    };
  };
in {
  secrets.weechat = {
    owner = my.username;
    inherit (config.my) group;
  };

  systemd.services."tmux-weechat-${my.username}" = {
    description = "WeeChat in a tmux session";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "nss-lookup.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      User = my.username;
      Group = config.my.group;
      Type = "forking";
      ExecStart     = "${pkgs.tmux}/bin/tmux -L weechat new-session -s weechat -d ${config.my.shellPath} -lc 'exec ${weechat}/bin/weechat'";
      ExecStartPost = "${pkgs.tmux}/bin/tmux -L weechat set-option status off \\; set-option mouse off";
    };
    restartIfChanged = false;
  };

  hm.xdg.configFile = mapAttrs' (name: _: {
    name = "weechat/${name}";
    value.source = utils.mkMutableSymlink (./. + "/${name}");
  }) (filterAttrs (name: _: hasSuffix ".conf" name) (builtins.readDir ./.));

  networking.firewall.allowedTCPPorts = [ relayPort ];
}
