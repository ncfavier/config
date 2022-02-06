{
  hm = {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      config = {
        global.warn_timeout = "999h";
      };
    };

    home.sessionVariables.DIRENV_LOG_FORMAT = "";
  };
}
