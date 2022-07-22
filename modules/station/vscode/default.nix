{ config, pkgs, ... }: {
  hm = {
    programs.vscode = {
      enable = true;
      package = pkgs.vscodium;
      extensions = with pkgs.vscode-extensions; [
        vscodevim.vim
        xadillax.viml
        jnoortheen.nix-ide
        haskell.haskell
        justusadam.language-haskell
        eugleo.magic-racket
        yzhang.markdown-all-in-one
        james-yu.latex-workshop
      ]
      # to update: nixpkgs/pkgs/applications/editors/vscode/extensions/update_installed_exts.sh
      ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "white";
          publisher = "arthurwhite";
          version = "1.3.6";
          sha256 = "1zybp2px5pqd0hkigvdxf9a8yb2j1fmw20sgi7h7pmsxdxpz7yzl";
        }
        {
          name = "agda-mode";
          publisher = "banacorn";
          version = "0.3.9";
          sha256 = "0iqp9mldlxbxh4zn3jid07m5cyyhvk0xd5iapqx020yw82s40fmb";
          postPatch = ''
            sed -i '/agda-mode-body {/,/font-size/{/font-size/d}' dist/style.css
          '';
        }
        {
          name = "codercoder-dark-theme";
          publisher = "CoderCoder";
          version = "1.2.2";
          sha256 = "1zlfv5l3sd7xag23i8i5zfh4p08p1nyy09rb2mm5m1nnflb84zas";
        }
        {
          name = "night-owl-light-bold";
          publisher = "feego";
          version = "0.0.11";
          sha256 = "19yrbkp0jpzv0rd0c5bxzkaa2xr76wq70zc9dfl79mb05h1spl69";
        }
        {
          name = "synthax";
          publisher = "foxhoundn";
          version = "0.1.13";
          sha256 = "029p1grrhaha9q8c5s5jvanbcajisrgpj0cna2pmx1xzsk7fw61z";
        }
        {
          name = "Theme-Lavender";
          publisher = "gerane";
          version = "0.0.5";
          sha256 = "0zaqm8x3pgjhsjlppi7ln5l66j150cr7m9m23xgmsix1xaqms0fd";
        }
        {
          name = "white-winter";
          publisher = "jker";
          version = "1.0.1";
          sha256 = "0g0sb2q7qg53l4xlczrkxl0qdydc2l28wg0xpq9s4bv03751i1pq";
        }
        {
          name = "vscode-theme-1984";
          publisher = "juanmnl";
          version = "0.3.4";
          sha256 = "0qv1h5cp6jdmay7s17nn5drna5qzmh3jgvx5qc5qp1kdrqr957j5";
        }
        {
          name = "vscode-theme-mr-pink";
          publisher = "juanmnl";
          version = "1.0.1";
          sha256 = "1i5wh0znhb7shr2lwfby14arlhnqa5l37ncbp2xn8ws45jwm1cvv";
        }
        {
          name = "vscoq";
          publisher = "maximedenes";
          version = "0.3.6";
          sha256 = "1sailpizg7zvncggdma9dyxdnga8jya1a2vswwij1rzd9il04j3g";
        }
        {
          name = "vscode-duotone-dark";
          publisher = "sallar";
          version = "0.3.3";
          sha256 = "1d7s49j2m4ga590iqnhb0ayafrz9f9lkl3warp8a1898767a1wrq";
        }
        {
          name = "lilac";
          publisher = "shubham-saudolla";
          version = "1.3.0";
          sha256 = "0bwwhvmm6k3rdlh17cafi9fqhy171j4dwbnipi9gy66s2z0kpz5h";
        }
      ];
    };

    xdg.configFile = {
      "VSCodium/User/settings.json".source = config.lib.meta.mkMutableSymlink ./settings.json;
      "VSCodium/User/keybindings.json".source = config.lib.meta.mkMutableSymlink ./keybindings.json;
    };
  };

  environment.etc.agda-in-path.source = pkgs.writeShellScript "agda-in-path" ''
    # needed because of https://github.com/banacorn/agda-mode-vscode/pull/112
    exec agda "$@"
  '';
}
