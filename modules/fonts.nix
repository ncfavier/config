{ lib, here, pkgs, ... }: with lib; {
  config = mkMerge [
    {
      console.font = pkgs.runCommandLocal "dina.psf" {} ''
        cd ${pkgs.bdf2psf}/share/bdf2psf
        sed 's/POINT_SIZE/AVERAGE_WIDTH/' ${pkgs.dina-font.bdf}/share/fonts/misc/Dina_r400-8.bdf |
        ${pkgs.bdf2psf}/bin/bdf2psf --fb - standard.equivalents ascii.set+useful.set+linux.set 512 "$out"
      '';
    }

    (mkIf here.isStation {
      fonts = {
        fonts = with pkgs; [
          source-serif-pro
          source-sans-pro
          source-code-pro
          source-han-serif
          source-han-sans
          source-han-mono
          twitter-color-emoji
          noto-fonts-emoji
          symbola
          dina-font
          tewi-font
          efont-unicode
          siji
        ];
        fontconfig = {
          enable = true;
          defaultFonts = {
            serif     = [ "Source Serif Pro" "Source Han Serif" ];
            sansSerif = [ "Source Sans Pro" "Source Han Sans" ];
            monospace = [ "Source Code Pro" "Source Han Mono" ];
            emoji     = [ "Twemoji" "Noto Color Emoji" "Symbola" ];
          };
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
                  <family>Twitter Color Emoji</family>
                  <family>Symbola</family>
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
        gucharmap
        (writeShellScriptBin "show-siji" ''
          exec ${xlibs.xfd}/bin/xfd -rows 23 -columns 28 -fn '-*-siji-*-10-*'
        '')
      ];
    })
  ];
}
