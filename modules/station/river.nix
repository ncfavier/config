{ lib, config, ... }: with lib; mkEnableModule [ "river" ] {
  programs.river = {
    enable = true;
    extraPackages = [];
  };

  hm = {
    wayland.windowManager.river = {
      enable = true;
      package = null;
      systemd.enable = false;

      settings = {
        map.normal = {
          "Super Return" = "spawn alacritty";
          "Super Q" = "close";
          "Super+Shift E" = "exit";
        };
        keyboard-layout = with config.services.xserver.xkb; "-options ${options} -variant ${variant} ${layout}";
      };
    };
  };
}
