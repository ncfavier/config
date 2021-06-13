{ pkgs, lib, config, my, here, ... }: {
  my.shell = pkgs.bashInteractive_5;

  environment.systemPackages = with pkgs; [
    (lib.hiPrio config.my.shell)
    man-pages
    man-pages-posix
    rlwrap
    ripgrep
    file
    fd
    tree
    ncdu
    gptfdisk
    zip
    unzip
    binutils
    gcc
    gnumake
    openssl
    imagemagick
    ffmpeg-full
    youtube-dl
    jq
    python3
    neofetch
    lesspass-cli
    (shellScriptWithDeps "upload" ../upload.sh [])
  ];

  environment.sessionVariables = rec {
    LESS = "ij3FRMK --mouse --wheel-lines=4";
    SYSTEMD_LESS = LESS;
    MANOPT = "--no-hyphenation";
    MANPAGER = "less -+F";
  };

  documentation = {
    dev.enable = true;
    man.generateCaches = true;
  };

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
      l = "ls -lh";
      ll = "ls -lah";
      o = "xdg-open";
      tall = "tail -f -n +1";
      s = "sudo systemctl";
      u = "systemctl --user";
      j = "journalctl";

      # Force alias expansion after these commands
      exec = "exec ";
      rlwrap = "rlwrap ";
      sudo = "sudo ";
      watch = "watch ";
    };
  };

  hm.programs = {
    bash = {
      enable = true;
      historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
      historyIgnore = [ "ls" "l" "ll" "la" ];
      shellOptions = [ "autocd" "extglob" "globstar" "histappend" ];
      sessionVariables._ZL_CD = "cd";
      shellAliases = lib.mapAttrs (n: _: "ssh -qt ${n}") my.machines;
      initExtra = ''
        ${builtins.readFile ./functions.bash}

        complete -v dp
        complete -F _command C
        complete_alias s _systemctl systemctl
        complete_alias u _systemctl systemctl --user
        complete_alias j _journalctl journalctl

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
