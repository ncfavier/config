{ config, lib, here, my, ... }: let
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
    matchBlocks = lib.listToAttrs (lib.concatLists (lib.mapAttrsToList (n: m: [ {
      name = lib.concatStringsSep " " ([
        m.wireguard.ipv6 m.wireguard.ipv4
        n "v4.${n}"
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

  # programs.mosh.enable = true;
  # programs.bash.shellAliases.mosh = "MOSH_TITLE_NOPREFIX=y mosh";
  #
  # nixpkgs.overlays = [
  #   (self: super: {
  #     mosh = super.mosh.overrideAttrs ({ patches ? [], ... }: {
  #       patches = patches ++ [
  #         (builtins.toFile "mosh-patch" ''
  #           Fix https://github.com/mobile-shell/mosh/issues/1130
  #           --- a/src/terminal/terminaldisplayinit.cc
  #           +++ b/src/terminal/terminaldisplayinit.cc
  #           @@ -127 +127 @@ Display::Display( bool use_environment )
  #           -      "xterm", "rxvt", "kterm", "Eterm", "screen"
  #           +      "xterm", "rxvt", "kterm", "Eterm", "alacritty", "screen", "tmux"
  #         '')
  #       ];
  #     });
  #   })
  # ];
}
