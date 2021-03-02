let
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

  programs.mosh.enable = true; # TODO patch alacritty title

  myHm.programs.ssh = {
    enable = true;
    matchBlocks = {
      "fd42::0:1 10.42.0.1 wo v4.wo monade.li up.monade.li" = {
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
