shopt -s lastpipe

terminal() {
    local instance title focus_title columns lines hold
    [[ $instance ]] && class=alacritty instance="$instance" focus-window && return
    [[ $focus_title ]] && class=alacritty title="$focus_title" focus-window && return
    exec alacritty \
        ${instance:+--class "$instance"} \
        ${title:+--title "$title"} \
        ${columns:+-o window.dimensions.columns="$columns"} \
        ${lines:+-o window.dimensions.lines="$lines"} \
        ${hold:+--hold} \
        ${*:+-e "$@"}
}

go() {
    if [[ $1 == -n ]]; then
        shift
        focus-window() { return 1; }
    fi
    case $1 in
        term|terminal)
            terminal &;;
        chat|irc)
            server=$(nix eval --raw config#lib.my.server.hostname)
            instance=irc terminal autossh -M 0 -- -qt "$server" tmux -L weechat attach &;;
        editor)
            focus_title='- VIM$' terminal vim &;;
        web|browser)
            class=firefox focus-window || exec firefox &;;
        mail)
            class=thunderbird focus-window || exec thunderbird &;;
        files)
            class=thunar focus-window || exec thunar &;;
        video)
            class=mpv focus-window;;
        volume)
            class=pavucontrol focus-window || exec pavucontrol &;;
        cal|calendar)
            instance=calendar title=calendar columns=64 lines=9 hold=1 terminal cal -3 &;;
        wifi)
            class=wpa_gui focus-window || exec wpa_gui &;;
    esac
}

focus-window() {
    wm_data=$(bspc wm -d)
    nodes=()
    jq <<< "$wm_data" -r --arg class "$class" --arg instance "$instance" '
        .monitors[].desktops[].root//empty |
        recurse(.firstChild//empty, .secondChild//empty) |
        select(.client != null) |
        select($class == "" or (.client.className | test($class; "i"))) |
        select($instance == "" or (.client.instanceName | test($instance; "i"))) |
        .id
    ' |
    while read -r node; do
        [[ ! $title || $(xtitle "$node") =~ $title ]] && nodes+=("$node")
    done
    (( ${#nodes[@]} )) || return

    jq <<< "$wm_data" -r '
        .focusHistory |
        reduce to_entries[] as {$key, value: {$nodeId}} (
            $ARGS.positional | map({key: ., value: -1}) | from_entries;
            (.[$nodeId | tostring]//empty) = $key
        ) | to_entries | min_by(.value).key
    ' --args "${nodes[@]}" |
    read -r node
    bspc node "$node" -f
}

cmd=$1
shift
case $cmd in
    go)
        go "$@";;
    focus-window)
        focus-window "$@";;
    focus-workspace)
        bspc desktop -f "$@";;
    move-window-to-workspace)
        bspc node -d "$@" -f;;
    quit)
        kill "$(< "$XDG_RUNTIME_DIR/bar.pid")" 2> /dev/null
        bspc quit;;
esac
