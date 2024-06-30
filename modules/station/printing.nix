{ pkgs, ... }: {
  # nixpkgs.config.allowUnfree = true;

  services.printing = {
    enable = true;
  };

  hardware.sane = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    simple-scan
  ];

  programs.system-config-printer.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  my.extraGroups = [ "lp" "scanner" ];
}
