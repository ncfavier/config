{ lib, here, config, pkgs, ... }: with lib; let
  port = 2242;
in {
  services.openssh = {
    enable = true;
    ports = [ port ];
    passwordAuthentication = !here.isServer;
    forwardX11 = true;
  };

  programs.ssh.extraConfig = ''
    StrictHostKeyChecking accept-new
  '';

  environment.systemPackages = with pkgs; [ autossh ];

  programs.mosh.enable = true;

  environment.variables.SSH_ASKPASS = mkForce "";
  environment.variables.MOSH_TITLE_NOPREFIX = "1";

  hm.programs.ssh = {
    enable = true;
    matchBlocks = mkMerge (
      mapAttrsToList (_: m: let
        hosts = concatStringsSep " " (
          [
            m.hostname
            "${m.hostname}.home"
            "${m.hostname}.local"
            m.wireguard.ipv4 m.wireguard.ipv6
          ] ++ optionals m.isServer [
            my.domain "*.${my.domain}"
          ] ++ optionals (m.hostname == here.hostname) [
            "localhost" "127.0.0.1" "::1"
          ] ++ m.ipv4 ++ m.ipv6
        );
      in {
        ${hosts} = {
          inherit port;
        } // optionalAttrs here.isStation {
          forwardX11 = true;
          forwardX11Trusted = true;
        };

        "unlock.${m.hostname}" = mkIf m.isServer {
          hostname = head m.ipv4;
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
