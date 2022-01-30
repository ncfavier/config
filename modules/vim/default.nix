{ lib, pkgs, ... }: with lib; {
  programs.vim = {
    defaultEditor = true;
    package = pkgs.vim_configurable;
  };

  hm = {
    programs.vim = {
      enable = true;
      plugins = with pkgs.vimPlugins; mkForce [
        nerdtree
        nerdcommenter
        vim-surround
        vim-easy-align
        vim-bracketed-paste
        vim-markdown
        haskell-vim
        vim-nix
        Coqtail
        coc-nvim
      ];
      extraConfig = readFile ./rc.vim;
    };

    home.packages = [ pkgs.nodejs ]; # for coc
    home.file.".vim/coc-settings.json".text = builtins.toJSON {
      languageserver = {
        haskell = {
          command = "haskell-language-server-wrapper";
          args = [ "--lsp" ];
          rootPatterns = [ "*.cabal" "stack.yaml" "cabal.project" "package.yaml" "hie.yaml" ];
          filetypes = [ "haskell" "lhaskell" ];
          initializationOptions.languageServerHaskell.hlintOn = false;
        };
        nix = {
          command = "rnix-lsp";
          filetypes = [ "nix" ];
        };
      };
    };
  };
}
