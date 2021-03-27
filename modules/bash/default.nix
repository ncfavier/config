{ pkgs, lib, ... }: {
  environment.systemPackages = [
    (lib.hiPrio pkgs.bashInteractive_5)
  ];

  my.shell = pkgs.bashInteractive_5;

  programs.bash = {
    promptInit = builtins.readFile ./prompt.bash;
    shellAliases = {
      # Default flags
      comm = "comm --output-delimiter=$'\\t\\t'";
      cp = "cp -i";
      df = "df -h";
      du = "du -h";
      ffmpeg = "ffmpeg -hide_banner";
      ffplay = "ffplay -hide_banner";
      ffprobe = "ffprobe -hide_banner";
      free = "free -h";
      ip = "ip --color=auto";
      ls = "ls --color=auto --group-directories-first";
      lsblk = "lsblk -o NAME,TYPE,FSTYPE,LABEL,UUID,SIZE,MOUNTPOINT";
      mv = "mv -i";

      # Shorthands
      C = "LC_ALL=C ";
      dp = "declare -p";
      fc-grep = "fc-list | rg -i";
      j = "jobs";
      l = "ls -lh";
      ll = "ls -lah";
      o = "xdg-open";
      tall = "tail -f -n +1";
      sd = "sudo systemctl";
      ud = "systemctl --user";

      # Force alias expansion after these commands
      exec = "exec ";
      rlwrap = "rlwrap ";
      sudo = "sudo ";
      watch = "watch ";
    };
  };

  myHm.programs = {
    bash = {
      enable = true;
      historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
      historyIgnore = [ "ls" "l" "ll" "la" ];
      shellOptions = [ "autocd" "extglob" "globstar" "histappend" ];
      sessionVariables._ZL_CD = "cd";
      initExtra = ''
        ${builtins.readFile ./functions.bash}

        complete -v dp
        complete -F _command C
        complete_alias sd _systemctl systemctl
        complete_alias ud _systemctl systemctl --user

        stty -ixon
        set -b +H
        [[ $BASH_STARTUP ]] && eval "$BASH_STARTUP"
      '';
    };

    readline = {
      enable = true;
      variables = {
        colored-completion-prefix = true;
        completion-display-width = 0;
        mark-symlinked-directories = true;
        show-all-if-ambiguous = true;
        page-completions = false;
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
