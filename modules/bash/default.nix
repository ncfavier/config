{ config, pkgs, lib, ... }: {
  environment.systemPackages = [ (lib.hiPrio pkgs.bashInteractive_5) ];

  my.shell = pkgs.bashInteractive_5;

  programs.bash.shellAliases = {
    C = "LC_ALL=C ";
    comm = "comm --output-delimiter=$'\\t\\t'";
    config = "sudo nixos-rebuild --flake ${config.my.mutableConfig} -v";
    cp = "cp -i";
    cxa = "clip | xargs";
    cxan = "clip | xargs -d'\\n'";
    df = "df -h";
    dp = "declare -p";
    du = "du -h";
    exec = "exec ";
    fc-grep = "fc-list | rg -i";
    free = "free -h";
    j = "jobs";
    ls = "ls --color=auto --group-directories-first";
    l = "ls -lh";
    ll = "ls -lah";
    lsblk = "lsblk -o NAME,TYPE,FSTYPE,LABEL,UUID,SIZE,MOUNTPOINT";
    mosh = "MOSH_TITLE_NOPREFIX=y mosh";
    mv = "mv -i";
    o = "xdg-open";
    ocaml = "rlwrap ocaml";
    rlwrap = "rlwrap ";
    sl = "sudo systemctl";
    ul = "systemctl --user";
    sudo = "sudo ";
    tail = "tail -f -n +1";
    watch = "watch ";
  };

  myHm.programs = {
    bash = {
      enable = true;
      historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
      historyIgnore = [ "ls" "l" "ll" "la" ];
      shellOptions = [ "autocd" "extglob" "globstar" "histappend" ];
      initExtra = ''
        ${builtins.readFile ./functions.bash}

        ${builtins.readFile ./init.bash}
      '';
    };

    readline = {
      enable = true;
      variables = {
        colored-completion-prefix = true;
        completion-display-width = 0;
        mark-symlinked-directories = true;
        show-all-if-ambiguous = true;
      };
      bindings = {
        "\\ef"  = "shell-forward-word";
        "\\eb"  = "shell-backward-word";
        "\\e[A" = "history-search-backward";
        "\\e[B" = "history-search-forward";
        "\\er"  = ''"\C-asudo \C-e"'';
        "\\ec"  = ''"\C-a\ed"'';
        "\\ev"  = ''"\C-a\edvim"'';
        "\\el"  = ''"\C-e | less"'';
      };
    };

    z-lua = {
      enable = true;
      enableAliases = true;
    };

    dircolors = {
      enable = true;
      settings = {
        TERM = "*";
        DIR = "1";
        LINK = "target";
        ORPHAN = "3;31";
        EXEC = "1;35";
      };
    };
  };
}
