{ lib, this, config, pkgs, ... }: with lib; {
  config = mkMerge [
    {
      fonts.fontconfig.enable = mkDefault false;
    }

    (mkIf this.isStation {
      nixpkgs.config.allowUnfree = true;

      console.font = pkgs.runCommandLocal "dina.psf" {} ''
        cd ${pkgs.bdf2psf}/share/bdf2psf
        ${if config.services.xserver.dpi != null && config.services.xserver.dpi >= 100 then
          "sed 's/POINT_SIZE 100/AVERAGE_WIDTH 80/' ${pkgs.dina-font.bdf}/share/fonts/misc/Dina_r400-10.bdf"
        else
          "sed 's/POINT_SIZE 80/AVERAGE_WIDTH 70/' ${pkgs.dina-font.bdf}/share/fonts/misc/Dina_r400-8.bdf"
        } |
        ${pkgs.bdf2psf}/bin/bdf2psf --fb - standard.equivalents ascii.set+useful.set+linux.set 256 "$out"
      '';

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
          (assert versionOlder twitter-color-emoji.version "15"; (pr 272078 "sha256-knBUacuhDSbY755uEYYXARsHo/TSEuHveLUuv74mu7Y=").twitter-color-emoji)
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
              <match target="scan"> <!-- TODO module -->
                <test name="family"><string>tewi</string></test>
                <edit name="charset" mode="assign">
                  <minus>
                    <name>charset</name>
                    <charset>
                      <int>0x2B1B</int> <!-- ⬛ -->
                    </charset>
                  </minus>
                </edit>
              </match>
              <match target="font">
                <test name="family"><string>tewi</string></test>
                <edit name="charset" mode="assign">
                  <minus>
                    <name>charset</name>
                    <charset>
                      <int>0x2B1B</int> <!-- ⬛ -->
                    </charset>
                  </minus>
                </edit>
              </match>
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
          exec ${xorg.xfd}/bin/xfd -rows 23 -columns 28 -fn '-*-siji-*-10-*'
        '')
      ];
    })
  ];
}
