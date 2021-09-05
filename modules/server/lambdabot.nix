{ config, pkgs, ... }: let
  tunnelPort = 6642;
in {
  secrets.lambdabot-ulminfo = {
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
      irc-persist-connect ulminfo localhost ${toString tunnelPort} lambdabot lambdabot
      rc ${config.secrets.lambdabot-ulminfo.path}
      admin + ulminfo:nf
      join ulminfo:#haskell
    '';
  };

  systemd.services.lambdabot = {
    wants = [ "nss-lookup.target" "stunnel.service" ];
    after = [ "nss-lookup.target" "stunnel.service" ];
  };

  services.stunnel = {
    enable = true;
    clients.ulminfo = {
      accept = "localhost:${toString tunnelPort}";
      connect = "ulminfo.fr:6666";
    };
  };
}
