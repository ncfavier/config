{ me, ... }: {
  home-manager.users.${me} = {
    programs.gpg.enable = true;

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      sshKeys = [ "D10BD70AF981C671C8EE4D288F23BAE560675CA3" ];
    };
  };
}
