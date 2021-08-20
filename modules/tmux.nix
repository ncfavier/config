{ config, ... }: {
  hm.programs.tmux = {
    enable = true;

    secureSocket = false;

    shortcut = "a";
    terminal = "tmux-256color";
    escapeTime = 100;
    baseIndex = 1;
    clock24 = true;
    sensibleOnTop = false;

    extraConfig = ''
      set -g history-limit 100000
      set -g mouse on
      set -g renumber-windows on
      set -g set-titles on
      set -g set-titles-string '#T'
      set -g status-left ""
      set -g status-right "#S"
      set -g status-style ""
      set -g window-status-current-format "#W"
      set -g window-status-current-style "bold fg=terminal"
      set -g window-status-format "#W"
      set -g window-status-separator "  "

      bind r source $XDG_DATA_HOME/tmux/tmux.conf
      bind -n C-q detach
      bind -n C-Left previous-window
      bind -n C-Right next-window
      bind -n WheelUpPane if -t = -F '#{==:#{pane_current_command},info}' 'send -N 2 Up' 'if -t = -F "#{||:#{mouse_any_flag},#{pane_in_mode}}" "send -M" "copy-mode -e -t ="'
      bind -n WheelDownPane if -t = -F '#{==:#{pane_current_command},info}' 'send -N 2 Down' 'send -M'
    '';
  };
}
