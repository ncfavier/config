{ lib, pkgs, ... }: with lib; {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "functions" (readFile ./functions.bash)) # meant to be sourced
    alacritty.terminfo
    ghostty.terminfo
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

  programs.command-not-found.enable = false;

  programs.bash = {
    promptInit = readFile ./prompt.bash;
    interactiveShellInit = ''
      if [[ ! -v SHLVL_BASE ]]; then
        export SHLVL_BASE=$SHLVL
      fi
    '';
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
      lsblk = "lsblk -o NAME,TYPE,UUID,PARTLABEL,FSTYPE,LABEL,SIZE,MOUNTPOINT";
      mv = "mv -i";
      nix = "nix -vL";
      pgrep = "pgrep -a";
      pkill = "pkill -e";

      # Shorthands
      C = "LC_ALL=C ";
      diff = "git diff --no-index --no-prefix";
      dp = "declare -p";
      fc-grep = "fc-list | rg -i";
      serve = "http-server";
      l = "ls -l";
      ll = "ls -la";
      nwd = "nix why-depends";
      o = "xdg-open";
      rgs = "rg --sort path";
      tall = "tail -f -n +1";
      s = "sudo systemctl";
      u = "systemctl --user";
      j = "journalctl";
      ju = "journalctl --user";
      top = "htop";
      vim-patch = "vim -c 'au! mangle' --cmd 'let b:EditorConfig_disable = 1'";

      # Force alias expansion after these commands
      exec = "exec ";
      rlwrap = "rlwrap ";
      sudo = "sudo ";
      watch = "watch ";
    };
  };

  hm = {
    programs = {
      bash = {
        enable = true;
        historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
        historyIgnore = [ "ls" "l" "ll" "la" ];
        shellOptions = [ "autocd" "extglob" "globstar" "histappend" ];
        initExtra = mkMerge [
          (mkBefore (readFile ./functions.bash))
          ''
            stty -ixon
            set -b +H

            complete -F _command C cxa cxan
            complete -v dp
            complete -f diff
            complete_alias drv nix derivation show
            complete_alias nwd nix why-depends
            complete_alias s systemctl
            complete_alias u systemctl --user
            complete_alias j journalctl
          ''
          (mkAfter ''
            if [[ $BASH_STARTUP ]]; then eval "$BASH_STARTUP"; fi
          '')
        ];
        logoutExtra = ''
          pkill xsel # prevents SSH connections from hanging
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
          OTHER_WRITABLE = "37;42";
        };
      };
    };
  };
}
