{ lib, config, pkgs, ... }: with lib; let
  exts = [
    {
      name = "white";
      publisher = "arthurwhite";
      sha256 = "1zybp2px5pqd0hkigvdxf9a8yb2j1fmw20sgi7h7pmsxdxpz7yzl";
      version = "1.3.6";
    }
    {
      name = "agda-mode";
      publisher = "banacorn";
      sha256 = "02r28a8y6pdjhad76z193xrlc4yk4fsynn064w7cff56gdc31bd5";
      version = "0.5.1";
    }
    {
      name = "codercoder-dark-theme";
      publisher = "CoderCoder";
      sha256 = "11agag6kh7fg9x3h5pbxx4gr2frqsskkph8niln6a7i0k9cz1wlc";
      version = "1.2.6";
    }
    {
      name = "night-owl-light-bold";
      publisher = "feego";
      sha256 = "19yrbkp0jpzv0rd0c5bxzkaa2xr76wq70zc9dfl79mb05h1spl69";
      version = "0.0.11";
    }
    {
      name = "synthax";
      publisher = "foxhoundn";
      sha256 = "029p1grrhaha9q8c5s5jvanbcajisrgpj0cna2pmx1xzsk7fw61z";
      version = "0.1.13";
    }
    {
      name = "theme-lavender";
      publisher = "gerane";
      sha256 = "0zaqm8x3pgjhsjlppi7ln5l66j150cr7m9m23xgmsix1xaqms0fd";
      version = "0.0.5";
    }
    {
      name = "white-winter";
      publisher = "jker";
      sha256 = "0g0sb2q7qg53l4xlczrkxl0qdydc2l28wg0xpq9s4bv03751i1pq";
      version = "1.0.1";
    }
    {
      name = "vscode-theme-1984";
      publisher = "juanmnl";
      sha256 = "0qv1h5cp6jdmay7s17nn5drna5qzmh3jgvx5qc5qp1kdrqr957j5";
      version = "0.3.4";
    }
    {
      name = "vscode-theme-mr-pink";
      publisher = "juanmnl";
      sha256 = "1i5wh0znhb7shr2lwfby14arlhnqa5l37ncbp2xn8ws45jwm1cvv";
      version = "1.0.1";
    }
    {
      name = "vscoq";
      publisher = "maximedenes";
      sha256 = "04m1dby6zfzg5nahnricjax28g47mgnja7d9cbll270i7ahnyncm";
      version = "2.2.1";
    }
    {
      name = "vscode-duotone-dark";
      publisher = "sallar";
      sha256 = "1d7s49j2m4ga590iqnhb0ayafrz9f9lkl3warp8a1898767a1wrq";
      version = "0.3.3";
    }
    {
      name = "lilac";
      publisher = "shubham-saudolla";
      sha256 = "0bwwhvmm6k3rdlh17cafi9fqhy171j4dwbnipi9gy66s2z0kpz5h";
      version = "1.3.0";
    }
  ];
in {
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
        elmtooling.elm-ls-vscode
        dhall.dhall-lang
        eugleo.magic-racket
        rust-lang.rust-analyzer
        yzhang.markdown-all-in-one
        james-yu.latex-workshop
        bungcip.better-toml
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace exts;
    };

    xdg.configFile = {
      "VSCodium/User/settings.json".source = config.lib.meta.mkMutableSymlink ./settings.json;
      "VSCodium/User/keybindings.json".source = config.lib.meta.mkMutableSymlink ./keybindings.json;
    };

    home.packages = [
      pkgs.coqPackages.vscoq-language-server
      (pkgs.writeShellScriptBin "update-vscode-extensions" ''
        ${pkgs.path}/pkgs/applications/editors/vscode/extensions/update_installed_exts.sh |
        nix eval -f - --apply ${escapeShellArg ''
          { extensions, ... }:
          let
            old = builtins.fromJSON (builtins.readFile ${builtins.toFile "exts.json" (builtins.toJSON exts)});
            new = builtins.listToAttrs (map (e: { inherit (e) name; value = e; }) extensions);
          in
          map (e: e // { inherit (new.''${e.name}) version sha256; }) old
        ''} |
        ${pkgs.nixfmt-rfc-style}/bin/nixfmt
      '')
    ];
  };
}
