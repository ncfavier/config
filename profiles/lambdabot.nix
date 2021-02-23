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
    package = pkgs.lambdabot.override {
      packages = p: with p; [
        adjunctions
        arithmoi
        array
        comonad
        containers
        kan-extensions
        lens
        linear
        megaparsec
        microlens-platform
        mtl
        profunctors
        safe
        split
        unordered-containers
        vector
      ];
    };
    script = ''
      irc-connect ulminfo localhost ${toString tunnelPort} lambdabot lambdabot
      rc ${config.sops.secrets.ulminfo-lambdabot.path}
      admin + ulminfo:nf
      join ulminfo:#haskell
    '';
  };

  systemd.services.lambdabot = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig.SupplementaryGroups = [
      config.users.groups.keys.name
    ];
  };

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
          rev = "e63f9f28e0ce1be080a17bb37764ff2a4f84294d";
          sha256 = "5FJAsRJRgFcg/CM3hISp3w/Veupl8Cj2qGd2SPpdjWM=";
        }}/lambdabot";
      });
    })
  ];
}