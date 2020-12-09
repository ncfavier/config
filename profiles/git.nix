{ pkgs, me, my, ... }: {
  home-manager.users.${me} = {
    programs.git = {
      enable = true;
      package = pkgs.gitAndTools.gitFull;

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
        c = "!git commit --allow-empty-message -m \"$*\" #";
        ca = "!git commit --allow-empty-message -am \"$*\" #";
        ce = "commit --edit";
        cf = "!git commit -m \"$(${pkgs.fortune}/bin/fortune -sn 60 | tr -s '[:space:]' '[ *]')\"";
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
      };
    };

    programs.gh = {
      enable = true;
      gitProtocol = "ssh";
    };
  };
}
