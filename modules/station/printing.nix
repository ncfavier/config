{ pkgs, ... }: {
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

  services.avahi = {
    enable = true;
    nssmdns = true;
  };
}
