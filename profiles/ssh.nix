{ me, ... }: let
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

  programs.mosh.enable = true;

  home-manager.users.${me}.programs.ssh = {
    enable = true;
    matchBlocks = {
      "10.42.0.1 fd42::0:1 wo wo.wg42 monade.li up.monade.li" = {
        inherit port;
        forwardX11 = true;
        forwardX11Trusted = true;
      };

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
