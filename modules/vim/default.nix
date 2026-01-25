{ lib, pkgs, ... }: with lib; {
  environment.variables.EDITOR = "vim";

  hm = {
    programs.neovim = {
      enable = true;
      vimAlias = true;
      viAlias = true;
      extraConfig = readFile ./init.vim;
      plugins = with pkgs.vimPlugins; [
        ctrlp
        nvim-lastplace
        editorconfig-vim
        vim-sleuth
        nvim-lspconfig
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
        kotlin-vim

        # https://github.com/mcchrish/vim-no-color-collections
        vim-colors-paramount
      ];
    };

    editorconfig = {
      enable = true;
      settings."*" = {
        trim_trailing_whitespace = true;
        insert_final_newline = true;
      };
    };
  };
}
