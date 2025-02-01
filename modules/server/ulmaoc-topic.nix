{ lib, config, pkgs, ... }: with lib; mkEnableModule [ "my-services" "ulmaoc-topic" ] {
  secrets.ulmaoc-topic = {
    owner = my.username;
    inherit (config.my) group;
  };

  systemd.services.ulmaoc-topic = {
    serviceConfig.User = my.username;
    path = [ pkgs.config-cli ];
    script = ''
      . config env
      (( day = $(TZ=EST date +%j) - $(date -d "december 1" +%j) + 1 )) || true
      read -r board < ${config.secrets.ulmaoc-topic.path}

      topic="Advent of Code $(date +%Y) https://adventofcode.com | Jour $day | Leaderboard $board | Spoilers -> #adventofcode-spoilers"

      echo "irc.server.ulminfo */msg ChanServ TOPIC #adventofcode $topic" > "$weechat_fifo"
    '';
    startAt = "12-1..25 00:00:00 EST";
  };

  systemd.timers.ulmaoc-topic.timerConfig.AccuracySec = "1s";
}
