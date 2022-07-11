{ lib, this, config, pkgs, ... }: with lib; let
  relayPort = 6642;
  scripts = [
    "color_popup.pl"
    "highmon.pl"
    "autosort.py"
    "buffer_autoset.py"
    "go.py"
    "screen_away.py"
    "title.py"
  ];
  weechat = pkgs.weechat.override {
    configure = { availablePlugins, ... }: {
      plugins = with availablePlugins; [ python perl ];
      init = "/exec -oc cat ${builtins.toFile "weechat-init" ''
        /script update
        /script install ${concatStringsSep " " scripts}
        /script load ${./colorize_nicks.py}
        /set sec.crypt.passphrase_command "cat ${config.secrets.weechat.path}"
        /set relay.network.bind_address ${this.wireguard.ipv4}
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

  systemd.services."tmux-weechat-${my.username}" = rec {
    description = "WeeChat in a tmux session";
    # create a user manager so that /run/user/$uid exists and hence SSH_AUTH_SOCK gets set correctly
    wants = [ "user@${toString config.my.uid}.service" "network-online.target" ];
    after = wants ++ [ "nss-lookup.target" ];
    wantedBy = [ "default.target" ];
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

  nixpkgs.overlays = [ (self: super: {
    weechat-unwrapped = super.weechat-unwrapped.overrideAttrs (o: {
      patches = o.patches or [] ++ [
        (self.fetchpatch {
          url = "https://github.com/weechat/weechat/commit/d4d8117461c20b075332bb3d2a1fc8493d92a9d7.patch";
          excludes = [ "ChangeLog.adoc" ];
          hash = "sha256-hMti1TGbtduxx6JoyG7gFGBROTa8bF0e44k+v5kIWRk=";
        })
        (self.fetchpatch {
          url = "https://github.com/weechat/weechat/commit/4d8df89bb5b56bd3ca7b281726722f9d21fefdf8.patch";
          excludes = [ "ChangeLog.adoc" ];
          hash = "sha256-Ew94eJnEYRcLWzazbC3mXp3NxzwQ/nYKdGCnBsGAvRQ=";
        })
      ];
    });
  }) ];
}
