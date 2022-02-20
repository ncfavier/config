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
        d = "diff --no-prefix";
        dh = "d HEAD";
        dc = "d --cached";
        do = "d origin";
        b = "branch";
        a = "add";
        aa = "add -A";
        au = "add -u";
        track = "add -N";
        c = ''!git commit --allow-empty-message -m "$*" #'';
        ca = "commit --amend";
        ce = "commit --edit";
        fixup = "commit --fixup";
        cf = ''!git commit -m "$(git-random-commit-message)"'';
        caf = ''!git commit --amend -m "$(git-random-commit-message)"'';
        co = "checkout";
        r = "reset";
        p = "push";
        pa = "push --all";
        pf = "push --force-with-lease";
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
        format.signOff = true;
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

  # TODO remove
  nixpkgs.overlays = [ (self: super: {
    python39 = super.python39.override {
      packageOverrides = python-self: python-super: {
        remarshal = python-super.remarshal.overrideAttrs (oldAttrs: {
            postPatch = ''
              substituteInPlace pyproject.toml \
                --replace "poetry.masonry.api" "poetry.core.masonry.api" \
                --replace 'PyYAML = "^5.3"' 'PyYAML = "*"' \
                --replace 'tomlkit = "^0.7"' 'tomlkit = "*"'
            '';
        });
      };
    };
  }) ];
}
