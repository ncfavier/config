{ lib, config, pkgs, ... }: with lib; let
  exts = [
    {
      hash = "sha256-9Pvzb29d13vgiU8DwasLUiyPVHK97RcnBA3f0q+4y/8=";
      name = "white";
      publisher = "arthurwhite";
      version = "1.3.6";
    }
    # {
    #   hash = "sha256-Lif7fvR2fozQDko0G74/+UhTnlbFjGAQj5eb2IIH61I=";
    #   name = "agda-mode";
    #   publisher = "banacorn";
    #   version = "0.5.7";
    #   # issues with later versions:
    #   # https://github.com/banacorn/agda-mode-vscode/issues/243
    #   # https://github.com/banacorn/agda-mode-vscode/issues/247
    #   # https://github.com/banacorn/agda-mode-vscode/issues/248
    #   # https://github.com/banacorn/agda-mode-vscode/issues/254
    #   # https://github.com/banacorn/agda-mode-vscode/issues/255
    # }
    {
      hash = "sha256-jPLwWZogHmUsjRbBO6fWODuRH+l93QJHT88dOM1TT4U=";
      name = "codercoder-dark-theme";
      publisher = "codercoder";
      version = "1.2.6";
    }
    {
      hash = "sha256-ydCrAyxg1XSoa4l9cDA3J3eh1Px9FQZaBvtfCe5c2ac=";
      name = "night-owl-light-bold";
      publisher = "feego";
      version = "0.0.11";
    }
    {
      hash = "sha256-PxjuztS/h16vUJYBeV/WUSq2rNqy6MIQTgoqmPMLNwk=";
      name = "synthax";
      publisher = "foxhoundn";
      version = "0.1.13";
    }
    {
      hash = "sha256-zQFdseqhR11fH6KmejIDJUhjaLH0xHup1FC+OzqqWH0=";
      name = "theme-lavender";
      publisher = "gerane";
      version = "0.0.5";
    }
    {
      hash = "sha256-+IYYyhlgL6ITvh08jgQVrPmGAe0zf0Y7oaM8fLBYGjw=";
      name = "white-winter";
      publisher = "jker";
      version = "1.0.1";
    }
    {
      hash = "sha256-RZ6SMs5thosLw6XvJwesHxdlcyvWnqCPV7VJc1mBYWM=";
      name = "vscode-theme-1984";
      publisher = "juanmnl";
      version = "0.3.4";
    }
    {
      hash = "sha256-e7NQuSxEc2S7uIvZM2hR2EKaFQl+OU5FhvosaD+AvMQ=";
      name = "vscode-theme-mr-pink";
      publisher = "juanmnl";
      version = "1.0.1";
    }
    {
      hash = "sha256-QBUTOFhdksHGkpYqgQIF2u+WodYH5PmMMvGFHwEEEIk=";
      name = "vscoq";
      publisher = "maximedenes";
      version = "2.2.6";
    }
    {
      hash = "sha256-OPOgjjkooaDQzYoPOmly6WenvAILWhxBKuqRKmQi+rQ=";
      name = "vscode-duotone-dark";
      publisher = "sallar";
      version = "0.3.3";
    }
    {
      hash = "sha256-sPw7wRfaGP9SvNEu3ogMJ3iIXYpOsRMgbXlMU+uGnC8=";
      name = "lilac";
      publisher = "shubham-saudolla";
      version = "1.3.0";
    }
  ];
  # TODO: port vim-colors-paramount
in {
  hm = {
    programs.vscode = {
      enable = true;
      package = config.lib.x.scaleElectronApp pkgs.vscodium;
      profiles.default.extensions = with pkgs.vscode-extensions; [
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
        tamasfe.even-better-toml
        (pkgs.vscode-utils.buildVscodeExtension {
          pname = "agda-mode-vscode";
          version = "0.5.7-patched";
          vscodeExtPublisher = "banacorn";
          vscodeExtName = "agda-mode";
          vscodeExtUniqueId = "banacorn.agda-mode";
          src = pkgs.buildNpmPackage {
            name = "agda-mode-vscode.vsix";
            src = pkgs.fetchFromGitHub {
              owner = my.githubUsername;
              repo = "agda-mode-vscode";
              rev = "live";
              hash = "sha256-yLwL2UxOyRe91Y0Lt5d00ie8UheMYUAGEoL2hZSp/8s=";
            };
            # src = pkgs.fetchFromGitHub {
            #   owner = "fredrik-bakke";
            #   repo = "agda-mode-vscode";
            #   rev = "autocomplete-literate";
            #   hash = "sha256-7Cc61IpEr0U1rrIc+gf6Mz5EZCN59TvoNVBiVgi934I=";
            # };
            npmDepsHash = "sha256-kYo6XsxiHp1tQ4JiPZ0PoXXla5WW2n1MFpCEQMqIjyc=";
            PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = 1;
            makeCacheWritable = true;
            nativeBuildInputs = [ pkgs.vsce ];
            forceGitDeps = true;
            installPhase = ''
              vsce package -o "$out"
            '';
          };
        })
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
          map (e: e // new.''${e.name}) old
        ''} |
        ${pkgs.nixfmt-rfc-style}/bin/nixfmt
      '')
    ];
  };
}
