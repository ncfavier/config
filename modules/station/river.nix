{ lib, config, ... }: with lib; mkEnableModule [ "my-programs" "river" ] {
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
          "Super Return" = "spawn ghostty";
          "Super Q" = "close";
          "Super+Shift E" = "exit";
        };
        keyboard-layout = with config.services.xserver.xkb; "-options ${options} -variant ${variant} ${layout}";
      };
    };
  };
}
