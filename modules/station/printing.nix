{ pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;

  services.printing = {
    enable = true;
    drivers = [ pkgs.epson-escpr ];
  };

  hardware.sane = {
    enable = true;
    extraBackends = [
      pkgs.epkowa
      (pkgs.writeTextFile {
        name = "epkowa.conf";
        destination = "/etc/sane.d/epkowa.conf";
        text = ''
          usb
          net printer.home
        '';
      })
    ];
  };

  environment.systemPackages = with pkgs; [
    simple-scan
  ];

  programs.system-config-printer.enable = true;

  services.avahi = {
    enable = true;
    nssmdns = true;
  };

  my.extraGroups = [ "lp" "scanner" ];
}
