{ pkgs, me, ... }: {
  home-manager.users.${me}.programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [ vim-nix ];
    settings = {
      mouse = "a";
    };
    extraConfig = ''
      set noswapfile
    '';
  };
}
