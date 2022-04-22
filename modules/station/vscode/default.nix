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
          version = "0.3.7";
          sha256 = "sha256-K+kXyJ1ySdPiQQBKWPCC3xNQii0zu1jeKJDkRv1qtEI=";
        }
        {
          name = "night-owl-light-bold";
          publisher = "feego";
          version = "0.0.11";
          sha256 = "19yrbkp0jpzv0rd0c5bxzkaa2xr76wq70zc9dfl79mb05h1spl69";
        }
        {
          name = "Theme-Lavender";
          publisher = "gerane";
          version = "0.0.5";
          sha256 = "0zaqm8x3pgjhsjlppi7ln5l66j150cr7m9m23xgmsix1xaqms0fd";
        }
        {
          name = "theme-github-bold";
          publisher = "gustavo";
          version = "0.0.4";
          sha256 = "0rcnhz26b78p4scm7yvdrixk46rs7ygh9hx2fgdjkqq7wy9fww4y";
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
      ];
    };

    xdg.configFile = {
      "VSCodium/User/settings.json".source = config.lib.meta.mkMutableSymlink ./settings.json;
      "VSCodium/User/keybindings.json".source = config.lib.meta.mkMutableSymlink ./keybindings.json;
    };
  };
}
