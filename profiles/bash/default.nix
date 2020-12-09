{ me, configPath, ... }: {
  home-manager.users.${me}.programs = {
    bash = {
      enable = true;
      historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
      historyIgnore = [ "ls" "l" "ll" "la" ];
      shellOptions = [ "autocd" "extglob" "globstar" "histappend" ];
      shellAliases = {
        C = "LC_ALL=C ";
        comm = "comm --output-delimiter=$'\\t\\t'";
        config = "sudo nixos-rebuild --flake ${configPath} -v";
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
        ls = "ls --color=auto --group-directories-first -h";
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
      initExtra = ''
        stty -ixon

        set -b +H

        ${builtins.readFile ./functions.bash}

        PS1='\[\e[0m\]''\'''${SSH_CONNECTION+$(hostname_short) }'\[\e[1m\]\w\[\e[0m\] \$ '
        PS2='\[\e[0m\]> '
        PROMPT_COMMAND='printf "\\033]0;%s\\007" "''${SSH_CONNECTION+$HOSTNAME:}$(pwd_short)"'

        if [[ $TERM != *linux* ]]; then
            trap '(( AT_PROMPT )) && AT_PROMPT=0 SECONDS_LAST=$SECONDS' debug
            PROMPT_COMMAND+=''${PROMPT_COMMAND:+; }'(( SECONDS - SECONDS_LAST >= 3 )) && { (( SECONDS_ELAPSED = SECONDS - SECONDS_LAST )); printf \\a; }; AT_PROMPT=1'
        fi

        [[ -v BASH_STARTUP ]] && eval "$BASH_STARTUP"
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
  };
}
