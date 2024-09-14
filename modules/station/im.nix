{ config, pkgs, ... }: {
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [
      mozc
      hangul
      typing-booster
      table table-others
    ];
  };

  hm = {
    xsession.windowManager.bspwm.startupPrograms = [
      "ibus restart || ibus-daemon --daemonize --replace --xim"
    ];

    xdg.configFile."mozc/ibus_config.textproto".text = ''
      engines {
        name: "mozc-jp"
        longname: "Mozc"
        layout: "default"
        layout_variant: ""
        layout_option: ""
        rank: 80
      }
      active_on_launch: True
    '';

    dconf.settings = {
      "desktop/ibus/general" = {
        use-system-keyboard-layout = true;
        preload-engines = [ "xkb:fr:oss:fra" "mozc-jp" "hangul" "typing-booster" "table:latex" ];
      };
      "desktop/ibus/general/hotkey".triggers = [ "<Super>i" ];
      "desktop/ibus/panel" = {
        show = 0;
        lookup-table-orientation = 1;
        use-custom-font = true;
        custom-font = config.theme.pangoFont;
      };
      "org/freedesktop/ibus/engine/hangul" = {
        initial-input-mode = "hangul";
        switch-keys = "Hangul,Control+space";
        hangul-keyboard = "ro";
      };
    };
  };
}
