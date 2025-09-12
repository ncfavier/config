{ lib, this, config, pkgs, ... }: with lib; {
  services.openssh = {
    enable = true;
    ports = mkIf (this.sshPort != null) [ this.sshPort ];
    settings.PasswordAuthentication = false;
    settings.X11Forwarding = true;
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
    enableDefaultConfig = false;
    matchBlocks = mkMerge (
      mapAttrsToList (_: m: let
        hosts = concatStringsSep " " (
          [
            m.hostname
            "${m.hostname}.home"
            "${m.hostname}.local"
            "${m.hostname}.${config.networking.wireguard.interface}"
          ] ++ optionals (m ? wireguard) [
            m.wireguard.ipv4 m.wireguard.ipv6
          ] ++ optionals m.isServer [
            my.domain "*.${my.domain}"
          ] ++ optionals (m.hostname == this.hostname) [
            "localhost" "127.0.0.1" "::1"
          ] ++ m.ipv4 ++ m.ipv6
        );
      in {
        ${hosts} = optionalAttrs (m.sshPort != null) {
          port = m.sshPort;
        } // optionalAttrs this.isStation {
          forwardX11 = true;
          forwardX11Trusted = true;
        };
      } // optionalAttrs m.isServer {
        "unlock.${m.hostname}" = {
          hostname = head m.ipv4;
          user = "root";
          extraOptions = {
            RemoteCommand = "cryptsetup-askpass";
            RequestTTY = "yes";
          };
        };
      }) (my.machinesWith "hostname") ++ [ {
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
