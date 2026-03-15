{ lib, this, config, ... }: with lib; let
  hasEmail = this.isServer && config.my-services.mailserver.enable; # TODO simplify
in {
  options = {
    systemd.services = mkOption {
      type = types.attrsOf (types.submodule {
        config.onFailure = mkIf hasEmail [ "notify-failure@%n.service" ];
      });
    };
  };

  config = mkMerge [
    {
      systemd.settings.Manager = {
        DefaultTimeoutStartSec = "30s";
        DefaultTimeoutStopSec = "15s";
      };

      systemd.user.extraConfig = ''
        DefaultTimeoutStartSec=30s
        DefaultTimeoutStopSec=15s
      '';
    }
    (mkIf hasEmail {
      systemd.services."notify-failure@" = {
        description = "Send e-mail notifications for failed units";
        serviceConfig.Type = "oneshot";
        onFailure = mkForce []; # avoid loops
        path = [ config.systemd.package ];
        scriptArgs = "%i";
        script = ''
          unit=$1
          ${config.services.mail.sendmailSetuidWrapper.source} ${escapeShellArg my.email} <<EOF
          From: ${this.hostname} <${this.hostname}@${my.domain}>
          Subject: systemd unit $unit failed
          Content-Transfer-Encoding: 8bit
          Content-Type: text/plain; charset=UTF-8

          $(systemctl status --full --lines=100 "$unit")
          EOF
        '';
      };
    })
  ];
}
