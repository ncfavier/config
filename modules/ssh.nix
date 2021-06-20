{ lib, my, here, config, pkgs, ... }: let
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

  hm.programs.ssh = {
    enable = true;
    matchBlocks = lib.mkMerge (
      lib.mapAttrsToList (_: m: let
        hosts = lib.concatStringsSep " " (
          [
            m.hostname
            m.wireguard.ipv4 m.wireguard.ipv6
          ] ++ lib.optionals m.isServer [
            my.domain "*.${my.domain}"
          ] ++ lib.optionals (m.hostname == here.hostname) [
            "localhost" "127.0.0.1" "::1"
          ] ++ m.ipv4 ++ m.ipv6
        );
      in {
        ${hosts} = {
          inherit port;
        } // lib.optionalAttrs here.isStation {
          forwardX11 = true;
          forwardX11Trusted = true;
        };

        "unlock.${m.hostname}" = lib.mkIf m.isServer {
          hostname = my.domain;
          addressFamily = "inet";
          inherit port;
          user = "root";
          extraOptions = {
            RemoteCommand = "cryptsetup-askpass";
            RequestTTY = "yes";
          };
        };
      }) my.machines ++ [ {
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
      } ]
    );
  };
}
