{ config, pkgs, secretsPath, ... }: let
  tunnelPort = 6642;
in {
  sops.secrets.ulminfo-lambdabot = {
    sopsFile = secretsPath + "/ulminfo-lambdabot";
    format = "binary";
    owner = config.users.users.lambdabot.name;
    group = config.users.users.lambdabot.group;
  };

  services.lambdabot = {
    enable = true;
    script = ''
      irc-connect ulminfo localhost ${toString tunnelPort} lambdabot lambdabot
      rc ${config.sops.secrets.ulminfo-lambdabot.path}
      admin + ulminfo:nf
      join ulminfo:#haskell
    '';
  };

  systemd.services.lambdabot.serviceConfig.SupplementaryGroups = [
    config.users.groups.keys.name
  ];

  services.stunnel = {
    enable = true;
    clients.ulminfo = {
      accept = "localhost:${toString tunnelPort}";
      connect = "ulminfo.fr:6666";
    };
  };

  nixpkgs.overlays = [
    (final: prev: {
      lambdabot = prev.lambdabot.overrideAttrs (drv: {
        src = "${final.fetchFromGitHub {
          owner = "lambdabot";
          repo = "lambdabot";
          rev = "87c3597122d030506f1b5aac81b42cb880194110";
          sha256 = "f69THxc7QbYrpJ5UUqEuKDf7E5Tbwt9KCEFWqJnDd2c=";
        }}/lambdabot";
        patches = [];
        postPatch = "";
      });
    })
  ];
}
