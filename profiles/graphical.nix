{ pkgs, config, me, ... }: {
  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
  };

  home-manager.users.${me} = {
    # wayland.windowManager.sway = {
    #   enable = true;
    #   config = {
    #     input."*" = with config.services.xserver; {
    #       xkb_layout = layout;
    #       xkb_variant = xkbVariant;
    #       xkb_options = xkbOptions;
    #     };
    #   };
    # };
    #
    # programs.waybar = {
    #   enable = true;
    #   systemd.enable = true;
    #   style = ''
    #     * {
    #       font-family: Dina;
    #     }
    #   '';
    # };

    xsession = {
      enable = true;
      windowManager.bspwm.enable = true;
    };

    services.sxhkd = {
      enable = true;
      keybindings = {
        "super + Return" = "urxvt";
      };
      extraPath = "/run/current-system/sw/bin";
    };

    home.packages = [ pkgs.dina-font ];
  };

  environment.systemPackages = with pkgs; [
    rxvt-unicode
  ];
}
