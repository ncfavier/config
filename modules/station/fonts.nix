{ pkgs, ... }: {
  nixpkgs.overlays = [ (pkgs: super: with pkgs; {
    efont-unicode = stdenv.mkDerivation rec { # https://github.com/NixOS/nixpkgs/pull/126593
      pname = "efont-unicode";
      version = "0.4.2";
      src = builtins.fetchTarball {
        url = "http://openlab.ring.gr.jp/efont/dist/unicode-bdf/${pname}-bdf-${version}.tar.bz2";
        sha256 = "0bib3jgikq8s1m96imw4mlgbl5cbq1bs5sqig74s2l2cdfx3jaqc";
      };
      nativeBuildInputs = with xorg; [ libfaketime bdftopcf fonttosfnt mkfontscale ];
      buildPhase = ''
        # convert bdf fonts to pcf
        for f in *.bdf; do
          bdftopcf -t -o "''${f%.bdf}.pcf" "$f"
        done
        gzip -n -9 *.pcf

        # convert bdf fonts to otb
        for f in *.bdf; do
            faketime -f "1970-01-01 00:00:01" \
            fonttosfnt -v -m 2 -o "''${f%.bdf}.otb" "$f"
        done
      '';
      installPhase = ''
        dir=share/fonts/misc
        install -D -m 644 -t "$out/$dir" *.otb *.pcf.gz
        install -D -m 644 -t "$bdf/$dir" *.bdf
        mkfontdir "$out/$dir"
        mkfontdir "$bdf/$dir"
      '';
      outputs = [ "out" "bdf" ];
      meta = with lib; {
        description = "The /efont/ Unicode bitmap font";
        homepage = "http://openlab.ring.gr.jp/efont/unicode/";
        license = licenses.bsd3;
        platforms = platforms.all;
      };
    };
    dina-font = stdenv.mkDerivation {
      pname = "dina-font";
      version = "2.92";

      src = fetchurl {
        url = "http://www.donationcoder.com/Software/Jibz/Dina/downloads/Dina.zip";
        sha256 = "1kq86lbxxgik82aywwhawmj80vsbz3hfhdyhicnlv9km7yjvnl8z";
      };

      nativeBuildInputs = with xorg;
        [ unzip bdftopcf mkfontscale fonttosfnt fontforge ];

      patchPhase = "sed -i 's/microsoft-cp1252/ISO8859-1/' *.bdf";

      buildPhase = ''
        newName() {
          test "''${1:5:1}" = i && _it=Italic || _it=
          case ''${1:6:3} in
            400) test -z $it && _weight=Medium ;;
            700) _weight=Bold ;;
          esac
          _pt=''${1%.bdf}
          _pt=''${_pt#*-}
          echo "Dina$_weight$_it$_pt"
        }
        # convert bdf fonts to pcf
        for i in *.bdf; do
          bdftopcf -t -o $(newName "$i").pcf "$i"
        done
        gzip -n -9 *.pcf
        # convert bdf fonts to otb
        for i in *.bdf; do
          fonttosfnt -o "$(newName "$i").otb" "$i"
          # fontforge -lang=ff -c "New(); Import(\"$i\"); Generate(\"$(newName $i).otb\")"
        done
      '';

      installPhase = ''
        install -D -m 644 -t "$out/share/fonts/misc" *.pcf.gz *.otb
        install -D -m 644 -t "$bdf/share/fonts/misc" *.bdf
        mkfontdir "$out/share/fonts/misc"
        mkfontdir "$bdf/share/fonts/misc"
      '';

      outputs = [ "out" "bdf" ];
    };
  }) ];

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

  # TODO remove "${}" https://nixpk.gs/pr-tracker.html?pr=126658
  console.font = "${pkgs.runCommandLocal "dina.psf" {} ''
    cd ${pkgs.bdf2psf}/share/bdf2psf
    sed 's/POINT_SIZE/AVERAGE_WIDTH/' ${pkgs.dina-font.bdf}/share/fonts/misc/Dina_r400-8.bdf |
    ${pkgs.bdf2psf}/bin/bdf2psf --fb - standard.equivalents ascii.set+useful.set+linux.set 512 "$out"
  ''}";

  environment.systemPackages = with pkgs; [
    gucharmap
    (writeShellScriptBin "show-siji" ''
      exec ${xlibs.xfd}/bin/xfd -rows 23 -columns 28 -fn '-*-siji-*-10-*'
    '')
  ];
}
