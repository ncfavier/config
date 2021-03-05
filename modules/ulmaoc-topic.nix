{ config, lib, here, secrets, me, my, ... }: {
  config = lib.mkIf here.isServer {
    sops.secrets.ulmaoc-leaderboard = {
      owner = me;
      inherit (my) group;
    };

    systemd.services.ulmaoc-topic = {
      serviceConfig.User = me;
      script = ''
        fifo=~/.weechat/weechat_fifo
        (( day = $(TZ=America/New_York date +%j) - $(date -d "december 1" +%j) + 1 ))
        board=$(< ${secrets.ulmaoc-leaderboard.path})

        topic="Advent of Code $(date +%Y) https://adventofcode.com | Jour $day | Leaderboard $board | Spoilers -> #adventofcode-spoilers"

        echo "irc.server.ulminfo */cs topic #adventofcode :$topic" > "$fifo"
      '';
      startAt = "12-1..25 05:00:00 UTC";
    };

    systemd.timers.ulmaoc-topic.timerConfig.AccuracySec = "1s";
  };
}
