{ lib, pkgs, ... }: with lib; {
  environment.variables.EDITOR = "vim";

  hm = {
    programs.neovim = {
      enable = true;
      vimAlias = true;
      viAlias = true;
      extraConfig = readFile ./rc.vim;
      plugins = with pkgs.vimPlugins; [
        ctrlp
        nvim-lastplace
        editorconfig-vim
        vim-sleuth
        nerdtree
        nerdcommenter
        vim-surround
        vim-easy-align
        vim-nix
        vim-nixhash
        vim-markdown
        haskell-vim
        agda-vim
        coq-vim
        # TODO https://github.com/mcchrish/vim-no-color-collections
        (pkgs.vimUtils.buildVimPluginFrom2Nix {
          name = "vim-colors-paramount";
          src = pkgs.fetchFromGitHub {
            owner = "owickstrom";
            repo = "vim-colors-paramount";
            rev = "a5601d36fb6932e8d1a6f8b37b179a99b1456798";
            hash = "sha256-j9nMjKYK7bqrGHprYp0ddLEWs1CNMudxXD13sOROVmY=";
          };
        })
        (pkgs.vimUtils.buildVimPluginFrom2Nix {
          name = "vim-colors-plain";
          src = pkgs.fetchFromGitHub {
            owner = "andreypopp";
            repo = "vim-colors-plain";
            rev = "master";
            hash = "sha256-ej7UbnpwH7C4cOsaRr4+OI6iqLyx1PnySY0LTTKRMCk=";
          };
        })
        (pkgs.vimUtils.buildVimPluginFrom2Nix {
          name = "colorbuddy";
          src = pkgs.fetchFromGitHub {
            owner = "tjdevries";
            repo = "colorbuddy.nvim";
            rev = "dev";
            hash = "sha256-PjVrlW4qEnn27BA2ERtW1/AYF4RVkGqvUBV8u95bOT4=";
          };
        })
        (pkgs.vimUtils.buildVimPluginFrom2Nix {
          name = "nvim-noirbuddy";
          src = pkgs.fetchFromGitHub {
            owner = "jesseleite";
            repo = "nvim-noirbuddy";
            rev = "master";
            hash = "sha256-fooegPQqqbnuBqHzBZU5onlDTuGcp6+Bv8pYcLnyy1E=";
          };
        })
      ];
      coc = {
        enable = true;
        settings = {
          languageserver = {
            nix = {
              command = "rnix-lsp";
              filetypes = [ "nix" ];
            };
            haskell = {
              command = "haskell-language-server";
              args = [ "--lsp" ];
              rootPatterns = [
                "*.cabal"
                "stack.yaml"
                "cabal.project"
                "package.yaml"
                "hie.yaml"
              ];
              filetypes = [ "haskell" "lhaskell" ];
            };
          };
        };
      };
    };

    editorconfig = {
      enable = true;
      settings."*" = {
        trim_trailing_whitespace = true;
        insert_final_newline = true;
        indent_style = "space";
      };
    };
  };
}
