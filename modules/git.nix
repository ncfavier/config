{ lib, pkgs, ... }: with lib; {
  environment.systemPackages = [ pkgs.git ];

  hm = {
    programs.git = {
      enable = true;
      package = pkgs.gitFull;

      userName = my.realName;
      userEmail = my.email;
      signing = {
        key = my.pgpFingerprint;
        signByDefault = true;
      };

      aliases = {
        i = "init";
        s = "status";
        d = "diff --no-prefix";
        dh = "d HEAD";
        dc = "d --cached";
        du = "d @{upstream}";
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
        pl = "pull --all --autostash";
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
          smtpEncryption = "ssl";
          smtpServerPort = 465;
          confirm = "always";
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
      (writeShellScriptBin "gh-default-branch" ''
        gh api graphql -F owner='{owner}' -F repo='{repo}' -f query='
          query($owner: String!, $repo: String!) {
            repository(owner: $owner, name: $repo) {
              defaultBranchRef { name }
            }
          }
        ' --jq .data.repository.defaultBranchRef.name
      '')
      (writeShellScriptBin "gh-prs-for-file" ''
        file=$1
        branch=''${2-$(gh-default-branch)}
        gh api graphql --paginate -F owner='{owner}' -F repo='{repo}' -F branch="$branch" -f query='
          query($owner: String!, $repo: String!, $branch: String!, $endCursor: String) {
            repository(owner: $owner, name: $repo) {
              pullRequests(first: 100, after: $endCursor, states: OPEN, baseRefName: $branch) {
                nodes {
                  number
                  files(first: 100) {
                    nodes { path }
                  }
                }
                pageInfo { hasNextPage endCursor }
              }
            }
          }
        ' | jq -r --arg file "$file" '.data.repository.pullRequests.nodes[] | select(.files.nodes | any(.path | test("^\($file)$"; ""))).number'
      '')
    ];
  };
}
