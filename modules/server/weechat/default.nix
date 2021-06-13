{ config, pkgs, lib, here, secrets, my, syncedFolders, ... }: let
  relayPort = 6642;
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
      scripts = with pkgs.weechatScripts; [ weechat-matrix ];
      init = "/exec -oc cat ${builtins.toFile "weechat-init" ''
        /set sec.crypt.passphrase_command "cat ${secrets.weechat-sec.path}"
        /set relay.network.bind_address ${here.wireguard.ipv4}
        /set relay.port.weechat ${toString relayPort}
        /set logger.file.path ${syncedFolders.irc-logs.path}
        /script install ${builtins.concatStringsSep " " scripts}
      ''}";
    };
  };
in {
  sops.secrets.weechat-sec = {
    owner = my.username;
    inherit (config.my) group;
  };

  # TODO linger module
  system.activationScripts."linger-${my.username}" = lib.stringAfter [ "users" ] ''
    /run/current-system/systemd/bin/loginctl enable-linger ${my.username}
  '';

  hm = {
    systemd.user.services.tmux-weechat = {
      Unit = {
        Description = "WeeChat in a tmux session";
        Wants = [ "network-online.target" ];
        After = [ "network-online.target" "nss-lookup.target" ];
      };
      Service = {
        Type = "forking";
        ExecStart     = "${pkgs.tmux}/bin/tmux -L weechat new-session -s weechat -d ${config.my.shellPath} -lc 'exec ${weechat}/bin/weechat'";
        ExecStartPost = "${pkgs.tmux}/bin/tmux -L weechat set-option status off \\; set-option mouse off";
      };
      Install.WantedBy = [ "default.target" ];
    };

    home.file = lib.mapAttrs' (name: _: {
      name = ".weechat/${name}";
      value.source = config.lib.meta.mkMutableSymlink (./. + "/${name}");
    }) (lib.filterAttrs (name: _: lib.hasSuffix ".conf" name) (builtins.readDir ./.));
  };

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