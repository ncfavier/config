{ lib, pkgs, ... }: with lib; {
  environment.systemPackages = [ pkgs.git ];

  hm = {
    programs.git = {
      enable = true;
      package = pkgs.gitFull;

      userName = my.realName;
      userEmail = my.email;
      signing = {
        key = my.email;
        signByDefault = true;
      };

      aliases = {
        i = "init";
        s = "status";
        d = "diff";
        dh = "diff HEAD";
        dc = "diff --cached";
        do = "diff origin";
        b = "branch";
        a = "add";
        aa = "add -A";
        au = "add -u";
        track = "add -N";
        c = ''!git commit --allow-empty-message -m "$*" #'';
        ca = "commit --amend";
        ce = "commit --edit";
        cf = ''!git commit -m "$(git-random-commit-message)"'';
        caf = ''!git commit --amend -m "$(git-random-commit-message)"'';
        co = "checkout";
        r = "reset";
        p = "push";
        pa = "push --all";
        pl = "pull --rebase --autostash";
        cl = "clone";
        cl1 = "clone --depth=1";
        l = "log --graph --oneline";
        la = "log --graph --oneline --all";
        sw = "switch";
      };

      extraConfig = {
        credential.helper = "store";
        advice = {
          detachedHead = false;
          pushNonFFCurrent = false;
        };
        init.defaultBranch = "main";
        pull.rebase = true;
        rebase = {
          autoStash = true;
          autoSquash = true;
        };
        diff.submodule = "log";
        color = {
          status = {
            added = "green bold";
            changed = "red bold";
            untracked = "red bold";
          };
          diff = {
            meta = "cyan";
            new = "green";
            old = "red";
          };
        };
        sendemail = {
          smtpServer = my.domain;
          smtpUser = my.email;
          smtpEncryption = "tls";
          smtpServerPort = 587;
        };
      };
    };

    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
      };
    };

    home.packages = with pkgs; [
      (writeShellScriptBin "git-random-commit-message" ''
        ${fortune}/bin/fortune -sn 80 \
            computers debian definitions disclaimer education fortunes goedel humorists linux \
            magic miscellaneous perl pets platitudes science songs-poems translate-me wisdom zippy |
        tr -s '[:space:]' '[ *]'
      '')
    ];
  };
}
