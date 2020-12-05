{
  nix = {
    trustedUsers = [ "root" "@wheel" ];

    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;

    extraOptions = ''
      warn-dirty = false
    '';
  };

  nixpkgs = {
    config.allowUnfree = true;
  };
}
