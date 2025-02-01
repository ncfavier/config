{ lib, this, config, pkgs, ... }: with lib; let
  relayPort = 6642;
  scripts = [
    "autosort.py"
    "buffer_autoset.py"
    "color_popup.pl"
    "colorize_nicks.py"
    "go.py"
    "highmon.pl"
    "screen_away.py"
  ];
  weechat = pkgs.weechat.override {
    configure = { availablePlugins, ... }: {
      plugins = with availablePlugins; [ python perl ];
      init = "/exec -oc cat ${builtins.toFile "weechat-init" ''
        /script update
        /script install ${concatStringsSep " " scripts}
        /mute set sec.crypt.passphrase_command "cat ${config.secrets.weechat.path}"
        /mute set relay.network.bind_address ${this.wireguard.ipv4}
        /mute set relay.port.weechat ${toString relayPort}
        /mute set logger.file.path ${config.synced.irc-logs.path}
      ''}";
    };
  };
in mkEnableModule [ "my-services" "weechat" ] {
  secrets.weechat = {
    owner = my.username;
    inherit (config.my) group;
  };

  systemd.services."weechat-${my.username}" = rec {
    description = "WeeChat in a tmux session";
    # create a user manager so that /run/user/$uid exists and hence SSH_AUTH_SOCK gets set correctly
    wants = [ "user@${toString config.my.uid}.service" "network-online.target" ];
    after = wants ++ [ "nss-lookup.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = my.username;
      Type = "forking";
      ExecStart     = "${pkgs.tmux}/bin/tmux -L weechat new-session -s weechat -d ${config.my.shellPath} -lc 'exec ${weechat}/bin/weechat'";
      ExecStartPost = "${pkgs.tmux}/bin/tmux -L weechat set-option status off \\; set-option mouse off";
    };
    restartIfChanged = false;
  };

  hm.xdg.configFile = mapAttrs' (name: _: {
    name = "weechat/${name}";
    value.source = config.lib.meta.mkMutableSymlink ./${name};
  }) (filterAttrs (name: _: hasSuffix ".conf" name) (builtins.readDir ./.));

  networking.firewall.allowedTCPPorts = [ relayPort ];

  environment.systemPackages = with pkgs; [ lolcat ];

  lib.shellEnv.weechat_fifo = "${config.hm.xdg.cacheHome}/weechat/weechat_fifo";

  my-services.ulmaoc-topic.enable = true;
}
