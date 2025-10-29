{ lib, config, pkgs, ... }: with lib; {
  programs.bash.promptInit = mkBefore ''
    . ${config.hm.programs.git.package}/share/bash-completion/completions/git-prompt.sh
  '';

  hm = {
    programs.git = {
      enable = true;
      package = pkgs.gitFull;

      signing = {
        key = my.pgpFingerprint;
        signByDefault = true;
      };

      ignores = [ ".direnv" ".envrc" ];

      settings = {
        user = {
          name = my.realName;
          email = my.email;
        };

        advice = {
          detachedHead = false;
          pushNonFFCurrent = false;
          skippedCherryPicks = false;
          statusUoption = false;
        };
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
        commit.verbose = 1;
        credential.helper = "store";
        diff.submodule = "log";
        format.signOff = true;
        init.defaultBranch = "main";
        pull.rebase = true;
        push = {
          default = "upstream";
          autoSetupRemote = true;
        };
        rebase = {
          autoStash = true;
          autoSquash = true;
        };
        submodule.recurse = true;
        sendemail = {
          smtpServer = my.domain;
          smtpUser = my.email;
          smtpEncryption = "ssl";
          smtpServerPort = 465;
          annotate = true;
          confirm = "always";
        };

        alias = {
          old = "bisect old";
          new = "bisect new";
          good = "bisect good";
          bad = "bisect bad";
          i = "init";
          s = "status";
          d = "diff --no-prefix";
          dh = "d HEAD";
          dc = "d --cached";
          du = "d @{upstream}";
          edit = "add -e";
          b = "branch";
          a = "add";
          aa = "add -A";
          au = "add -u";
          track = "add -N";
          c = ''!git commit --allow-empty-message -m "$*" #'';
          ca = "commit --amend";
          ce = "commit --edit";
          fixup = "commit --fixup";
          co = "checkout";
          cr = ''!git commit -m "$(git-random-commit-message)"'';
          r = "reset";
          p = "push";
          pa = "push --all";
          pf = "push --force-with-lease";
          pl = "pull --all --recurse-submodules --autostash";
          cl = "clone";
          cl1 = "clone --depth=1";
          l = "log --graph --oneline";
          la = "log --graph --oneline --all";
          sw = "switch";
          cat = "cat-file -p";
          yeet = "restore";
          w = "worktree";
          rebuild = "clean -Xd";
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
      glab
      (writeShellScriptBin "git-random-commit-message" ''
        set -eo pipefail
        url=$(${curl}/bin/curl -fsSw '%{redirect_url}' https://en.wiktionary.org/wiki/Special:Random)
        title=$(${curl}/bin/curl -fsSL "$url" | ${htmlq}/bin/htmlq --text title)
        title=''${title% - Wiktionary*}
        printf '%s\n\n%s\n' "$title" "$url"
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
      (writeShellScriptBin "gh-gist-clone-all" ''
        cd ~/git/gist
        gh gist list -L 10000 | while read -r id _; do
          gh gist clone "$id"
        done
      '')
    ];
  };
}
