{ pkgs, lib, ... }: {
  console = {
    earlySetup = true;
    useXkbConfig = true;
  };

  environment.etc.issue = lib.mkForce {
    text = ''
      \e{magenta}\n\e{reset} | \e{reset}\l\e{reset} | \d \t

    '';
  };

  # TODO PR services.mingetty.extraArgs = "--nohostname";
  systemd.services."getty@".serviceConfig.ExecStart = lib.mkForce [
    ""
    "@${pkgs.util-linux}/sbin/agetty agetty --login-program ${pkgs.shadow}/bin/login --noclear --nohostname --keep-baud %I 115200,38400,9600 $TERM"
  ];
}
