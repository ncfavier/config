{ lib, config, pkgs, pkgsPR, ... }: with lib; {
  hm.programs.alacritty = {
    enable = true;
    settings = with config.theme; {
      window = {
        dimensions = {
          columns = 80;
          lines = 25;
        };
        padding = {
          x = padding;
          y = padding;
        };
        decorations = "none";
      };
      font = {
        normal.family = font;
        size = fontSize;
      };
      colors = {
        primary = {
          inherit background foreground;
        };
        normal = {
          black   = background;
          red     = hot;
          green   = cold;
          yellow  = hot;
          blue    = cold;
          magenta = hot;
          cyan    = cold;
          white   = darkGrey;
        };
        bright = {
          black   = lightGrey;
          red     = hot;
          green   = cold;
          yellow  = hot;
          blue    = cold;
          magenta = hot;
          cyan    = cold;
          white   = foreground;
        };
      };
      selection.save_to_clipboard = true;
      cursor.style.blinking = "Always";
      key_bindings = [
        { key =  3; mods = "Alt"; chars = "\\e2"; }
        { key =  8; mods = "Alt"; chars = "\\e7"; }
        { key = 10; mods = "Alt"; chars = "\\e9"; }
        { key = 11; mods = "Alt"; chars = "\\e0"; }
      ];
    };
  };

  nixpkgs.overlays = [ (pkgs: prev: {
    alacritty = prev.alacritty.override {
      rustPlatform = prev.rustPlatform // {
        buildRustPackage = o:
          prev.rustPlatform.buildRustPackage (removeAttrs o [ "cargoSha256" ] // {
            cargoHash = "sha256-LtPn99KJ45sTsGBcTKCOsyAfEdwrtmWUAi9eP+jQgCs=";
            version = "0.9.0";
            src = pkgs.fetchFromGitHub {
              owner = "alacritty";
              repo = "alacritty";
              rev = "8cda3d140574cbd8bd0fd8e89667ef67a4a1f900";
              sha256 = "LzNDbZlAIYB33bT7ZhKyb9dtPDV9ep10D9ZnO+az8do=";
            };
            patches = [];
            doCheck = false;
          });
      };
    };
  }) ];
  cachix.derivationsToPush = [ pkgs.alacritty ];
}
