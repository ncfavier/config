{ lib, ... }: with lib; {
  hm = {
    programs.gpg.enable = true;

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      sshKeys = [ my.pgpKeygrip ];
    };
  };
}
