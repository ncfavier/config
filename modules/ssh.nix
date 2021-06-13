{ config, pkgs, lib, here, my, ... }: let
  port = 2242;
in {
  services.openssh = {
    enable = true;
    ports = [ port ];
    passwordAuthentication = false;
    forwardX11 = true;
  };

  programs.ssh.extraConfig = ''
    StrictHostKeyChecking accept-new
  '';

  environment.systemPackages = [ pkgs.autossh ];

  myHm.programs.ssh = {
    enable = true;
    matchBlocks = lib.listToAttrs (lib.concatLists (lib.mapAttrsToList (n: m: [ { # TODO make this more readable
      name = lib.concatStringsSep " " ([
        m.wireguard.ipv6 m.wireguard.ipv4
        n
      ] ++ lib.optionals m.isServer [ my.domain "*.${my.domain}" ]); # TODO add wan ips
      value = {
        inherit port;
      } // lib.optionalAttrs here.isStation {
        forwardX11 = true;
        forwardX11Trusted = true;
      };
    } ] ++ lib.optionals m.isServer [ {
      name = "unlock.${n}";
      value = {
        hostname = my.domain;
        addressFamily = "inet";
        inherit port;
        user = "root";
        extraOptions = {
          RemoteCommand = "cryptsetup-askpass";
          RequestTTY = "yes";
        };
      };
    } ]) my.machines)) // {
      "ens sas sas.eleves.ens.fr" = {
        hostname = "sas.eleves.ens.fr";
        user = "nfavier";
      };

      "phare phare.normalesup.org" = {
        hostname = "phare.normalesup.org";
        user = "nfavier";
      };

      "zeus zeus.ens.wtf" = {
        hostname = "zeus.ens.wtf";
        port = 4022;
        user = "nf";
      };
    };
  };
}
