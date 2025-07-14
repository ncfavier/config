{ lib, this, config, pkgs, ... }: with lib; {
  config = mkMerge [
    {
      fonts.fontconfig.enable = mkDefault false;
    }

    (mkIf this.isStation {
      nixpkgs.config.allowUnfree = true;

      console.packages = [ pkgs.terminus_font ];
      console.font =
        if config.services.xserver.dpiScaleFactor < 1.5
        then "ter-116n"
        else "ter-128b";

      fonts = {
        packages = with pkgs; [
          source-serif
          source-sans
          source-code-pro
          source-han-serif
          source-han-sans
          source-han-mono
          iosevka
          julia-mono
          jetbrains-mono
          roboto
          inriafonts
          twitter-color-emoji
          noto-fonts
          noto-fonts-emoji
          symbola
          dina-font
          tewi-font
          efont-unicode
          siji
          babelstone-han
          eb-garamond
          crimson-pro
          alice
          libre-baskerville
          libertinus
        ];
        fontconfig = {
          enable = true;
          defaultFonts = {
            serif     = [ "Libertinus Serif" "Source Serif 4" "Source Han Serif" "emoji" ];
            sansSerif = [ "Source Han Sans" "Source Sans 3" "emoji" ]; # Source Han Sans includes most glyphs from Source Sans and is slightly larger
            monospace = [ "JuliaMono" "Source Code Pro" "Source Han Mono" "emoji" ];
            emoji     = [ "Twitter Color Emoji" "Noto Color Emoji" "Symbola" ];
          };
          # test: ™ ´ ” ☺ 🦢 🪿 π œuf ✓ → ∀ ⬛🟩
          localConf = ''
            <?xml version='1.0'?>
            <!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
            <fontconfig>
              <alias binding="same">
                <family>bitmap</family>
                <prefer>
                  <family>Dina</family>
                  <family>tewi</family>
                  <family>Biwidth</family>
                  <family>emoji</family>
                </prefer>
              </alias>
              <alias binding="same">
                <family>Helvetica</family>
                <prefer>
                  <family>sans-serif</family>
                </prefer>
              </alias>
              <alias binding="same">
                <family>Arial</family>
                <prefer>
                  <family>sans-serif</family>
                </prefer>
              </alias>
              <alias binding="same">
                <family>Liberation Mono</family>
                <prefer>
                  <family>monospace</family>
                </prefer>
              </alias>
              <selectfont>
                <rejectfont>
                  <pattern>
                    <patelt name="family"><string>Biwidth</string></patelt>
                    <patelt name="pixelsize"><int>10</int></patelt>
                  </pattern>
                </rejectfont>
                <rejectfont>
                  <pattern>
                    <patelt name="family"><string>Lucida</string></patelt>
                  </pattern>
                </rejectfont>
              </selectfont>
            </fontconfig>
          '';
        };
      };

      environment.systemPackages = with pkgs; [
        (writeShellScriptBin "show-siji" ''
          exec ${xorg.xfd}/bin/xfd -rows 23 -columns 28 -fn '-*-siji-*-10-*'
        '')
      ];
    })
  ];
}
