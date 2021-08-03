{ lib, here, config, pkgs, ... }: with lib; {
  my.shell = pkgs.bashInteractive_5;

  environment.systemPackages = with pkgs; [
    (hiPrio config.my.shell)
    man-pages
    man-pages-posix
    rlwrap
    bat
    ripgrep
    file
    fd
    tree
    ncdu
    lsof
    gptfdisk
    pciutils
    zip
    unzip
    config.boot.kernelPackages.bcc
    binutils
    gcc
    gnumake
    openssl
    imagemagick
    ffmpeg-full
    youtube-dl
    amfora
    jq
    python3
    neofetch
    lesspass-cli
    tmsu
    (shellScriptWithDeps "upload" ./upload.sh [])
    (shellScriptWithDeps "order" ./order.sh [])
  ];

  environment.sessionVariables = rec {
    LESS = "ij3FRMK --mouse --wheel-lines=4";
    SYSTEMD_LESS = LESS;
    LESSHISTFILE = "-";
    MANOPT = "--no-hyphenation";
    MANPAGER = "less -+F";
    GROFF_SGR = "1";
    GROFF_BIN_PATH = "${pkgs.writeShellScriptBin "grotty" ''
      exec ${pkgs.groff}/bin/grotty -i "$@"
    ''}/bin";
  };

  documentation = {
    dev.enable = true;
  };

  programs.command-not-found.enable = false;

  programs.bash = {
    promptInit = readFile ./prompt.bash;
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
      ls = "ls -h --color=auto --group-directories-first";
      lsblk = "lsblk -o NAME,TYPE,FSTYPE,LABEL,UUID,SIZE,MOUNTPOINT";
      mv = "mv -i";

      # Shorthands
      C = "LC_ALL=C ";
      dp = "declare -p";
      fc-grep = "fc-list | rg -i";
      l = "ls -l";
      ll = "ls -la";
      o = "xdg-open";
      rgs = "rg --sort path";
      tall = "tail -f -n +1";
      s = "sudo systemctl";
      u = "systemctl --user";
      j = "journalctl";
      what = "_realcommand ";

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
      initExtra = ''
        ${readFile ./completion.bash}
        ${readFile ./functions.bash}

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
