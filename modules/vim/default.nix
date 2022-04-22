{ lib, pkgs, ... }: with lib; {
  programs.vim.defaultEditor = true;

  hm = {
    programs.vim = {
      enable = true;
      plugins = with pkgs.vimPlugins; mkForce [
        ctrlp
        nerdtree
        nerdcommenter
        vim-sleuth
        vim-surround
        vim-easy-align
        vim-bracketed-paste
        vim-markdown
        haskell-vim
        vim-nix
        Coqtail
        coc-nvim
        agda-vim
      ];
      extraConfig = readFile ./rc.vim;
    };

    home.packages = [ pkgs.nodejs ]; # for coc
    home.file.".vim/coc-settings.json".text = builtins.toJSON {
      languageserver = {
        nix = {
          command = "rnix-lsp";
          filetypes = [ "nix" ];
        };
      };
    };
  };
}
