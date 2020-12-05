{ config, me, my, secretsPath, ... }: {
  sops.secrets.ulmaoc-leaderboard = {
    sopsFile = "${secretsPath}/ulmaoc-leaderboard";
    format = "binary";
    owner = me;
    inherit (my) group;
  };

  systemd.services.ulmaoc-topic = {
    serviceConfig.User = me;
    script = ''
      fifo=~/.weechat/weechat_fifo
      (( day = $(TZ=America/New_York date +%j) - $(date -d "december 1" +%j) + 1 ))
      board=$(< ${config.sops.secrets.ulmaoc-leaderboard.path})

      topic="Advent of Code 2020 https://adventofcode.com | Jour $day | Leaderboard $board | Spoilers -> #adventofcode-spoilers"

      echo "irc.server.ulminfo */cs topic #adventofcode :$topic" > "$fifo"
    '';
    startAt = "05:00:00 UTC";
  };
}
