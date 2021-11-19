{ lib, config, pkgs, ... }: with lib; {
  secrets.ulmaoc-topic = {
    owner = my.username;
    inherit (config.my) group;
  };

  systemd.services.ulmaoc-topic = {
    serviceConfig.User = my.username;
    path = [ pkgs.config-cli ];
    script = ''
      . config env
      (( day = $(TZ=America/New_York date +%j) - $(date -d "december 1" +%j) + 1 ))
      read -r board < ${config.secrets.ulmaoc-topic.path}

      topic="Advent of Code $(date +%Y) https://adventofcode.com | Jour $day | Leaderboard $board | Spoilers -> #adventofcode-spoilers"

      echo "irc.server.ulminfo */msg ChanServ TOPIC #adventofcode $topic" > "$weechat_fifo"
    '';
    startAt = "12-1..25 05:00:00 UTC";
  };

  systemd.timers.ulmaoc-topic.timerConfig.AccuracySec = "1s";
}
