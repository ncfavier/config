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
        # TODO https://github.com/mcchrish/vim-no-color-collections
        colorbuddy-nvim
        (pkgs.vimUtils.buildVimPluginFrom2Nix {
          name = "nvim-noirbuddy";
          src = pkgs.fetchFromGitHub {
            owner = "jesseleite";
            repo = "nvim-noirbuddy";
            rev = "7d92fc64ae4c23213fd06f0464a72de45887b0ba";
            hash = "sha256-r+HO4lTXYotbC7rsD/3RpbjDofHAIrUrikAhyFnimuM=";
          };
        })
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
