{ config, pkgs, ... }: {
  nixpkgs.overlays = [ (self: super: {
    ibus = super.ibus.overrideAttrs (old: {
      patches = old.patches or [] ++ [ (pkgs.fetchpatch {
        url = "https://patch-diff.githubusercontent.com/raw/ibus/ibus/pull/2425.patch";
        hash = "sha256-Rp+RmEpnWtH4OXRGmY++5dJX9UoQS5A8S8BJKYd0yQc=";
      }) ];
    });
  }) ];
  cachix.derivationsToPush = [ pkgs.ibus ] ++ config.i18n.inputMethod.ibus.engines;

  i18n.inputMethod = {
    enabled = "ibus";
    ibus.engines = with pkgs.ibus-engines; [
      mozc
      hangul
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
        preload-engines = [ "xkb:fr:oss:fra" "mozc-jp" "hangul" ];
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
