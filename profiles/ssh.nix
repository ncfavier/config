{
  services.openssh = {
    enable = true;
    ports = [ 2242 ];
    passwordAuthentication = false;
  };

  programs.mosh.enable = true;
}
