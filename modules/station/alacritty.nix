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
        size = 7;
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

  nixpkgs.overlays = [ (self: super: {
    alacritty = super.alacritty.override {
      rustPlatform = super.rustPlatform // {
        buildRustPackage = o:
          super.rustPlatform.buildRustPackage (removeAttrs o [ "cargoSha256" ] // {
            cargoHash = "sha256-LtPn99KJ45sTsGBcTKCOsyAfEdwrtmWUAi9eP+jQgCs=";
            version = "0.9.0";
            src = self.fetchFromGitHub {
              owner = "alacritty";
              repo = "alacritty";
              rev = "cf35a2019162c6055e4a4c152976a424ba10869d";
              sha256 = "dX/m+RAN/wkAY8fwJwAnPCxvfxAlOVFuU/W1YkP94io=";
            };
            doCheck = false;
          });
      };
    };
  }) ];
}
