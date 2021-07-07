{ lib, theme, ... }: with lib; {
  nixpkgs.overlays = [ (self: super: {
    alacritty = super.alacritty.override {
      rustPlatform = super.rustPlatform // {
        buildRustPackage = o:
          super.rustPlatform.buildRustPackage (removeAttrs o [ "cargoSha256" ] // {
            cargoHash = "sha256-m8O88vYFstDfP/59uFzET5ODyAO4pBj0lOceJ9Ml8dI=";
            src = self.fetchFromGitHub {
              owner = "ncfavier";
              repo = "alacritty";
              rev = "reload-on-usr1";
              sha256 = "sha256-XueRjS+JzWbtvvJ5puK1AA8Xr6kDCs9R/H5Ws5PQDjQ=";
            };
          });
      };
    };
  }) ];
  hm.programs.alacritty = {
    enable = true;
    settings = with theme; {
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
}
