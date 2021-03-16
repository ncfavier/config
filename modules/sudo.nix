{
  security.sudo = {
    wheelNeedsPassword = false;
    extraConfig = ''
      Defaults env_keep+="SSH_CONNECTION SSH_CLIENT SSH_TTY"
    '';
  };
}
