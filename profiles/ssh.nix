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

  myHm.programs.ssh = {
    enable = true;
    matchBlocks = {
      "fd42::0:1 10.42.0.1 wo v4.wo monade.li *.monade.li" = { # TODO add other machines
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

  programs.mosh.enable = true;

  nixpkgs.overlays = [
    (self: super: {
      mosh = super.mosh.overrideAttrs ({ patches ? [], ... }: {
        patches = patches ++ [
          (builtins.toFile "mosh-patch" ''
            Fix https://github.com/mobile-shell/mosh/issues/1130
            --- a/src/terminal/terminaldisplayinit.cc
            +++ b/src/terminal/terminaldisplayinit.cc
            @@ -127 +127 @@ Display::Display( bool use_environment )
            -      "xterm", "rxvt", "kterm", "Eterm", "screen"
            +      "xterm", "rxvt", "kterm", "Eterm", "alacritty", "screen", "tmux"
          '')
        ];
      });
    })
  ];
}
