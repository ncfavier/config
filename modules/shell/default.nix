{ inputs, lib, here, config, pkgs, ... }: with lib; {
  environment.systemPackages = with pkgs; [
    jq
    alacritty.terminfo
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
      nix = "nix -v";

      # Shorthands
      C = "LC_ALL=C ";
      diff = "git diff --no-index --no-prefix";
      dp = "declare -p";
      drv = "nix show-derivation";
      fc-grep = "fc-list | rg -i";
      l = "ls -l";
      ll = "ls -la";
      nwd = "nix why-depends";
      o = "xdg-open";
      rgs = "rg --sort path";
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

  hm = {
    disabledModules = [ "programs/bash.nix" ];
    imports = [ "${inputs.home-manager-bash}/modules/programs/bash.nix" ]; # TODO remove

    options.programs.bash.completion = mkOption { # TODO PR
      description = "Completion commands";
      type = types.lines;
      default = "";
    };

    config = {
      programs = {
        bash = {
          enable = true;
          historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
          historyIgnore = [ "ls" "l" "ll" "la" ];
          shellOptions = [ "autocd" "extglob" "globstar" "histappend" ];
          initExtra = ''
            ${readFile ./functions.bash}

            ${config.hm.programs.bash.completion}

            stty -ixon
            set -b +H
            [[ $BASH_STARTUP ]] && eval "$BASH_STARTUP"
          '';
          completion = ''
            complete -F _command C cxa cxan
            complete -v dp
            complete_alias drv _complete_nix nix show-derivation
            complete -f nwd # TODO
            complete_alias s _systemctl systemctl
            complete_alias u _systemctl systemctl --user
            complete_alias j _journalctl journalctl
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
    };
  };
}
