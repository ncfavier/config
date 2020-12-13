{
  services.openssh = {
    enable = true;
    ports = [ 2242 ];
    passwordAuthentication = false;
    forwardX11 = true;
  };

  # TODO home-manager hosts config
  programs.ssh.extraConfig = ''
    StrictHostKeyChecking accept-new
  '';

  programs.mosh.enable = true;
}
