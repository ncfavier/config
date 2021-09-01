shopt -s lastpipe

. config env

focus-window() {
    local node wm_data=$(bspc wm -d)
    local -A nodes=()
    jq <<< "$wm_data" -r --arg class "$class" --arg instance "$instance" '
        (
            .monitors[].desktops[].root//empty |
            recurse(.firstChild//empty, .secondChild//empty) |
            select(.client != null) |
            select($class == "" or (.client.className | test($class; "i"))) |
            select($instance == "" or (.client.instanceName | test($instance; "i"))) |
            .id
        ),
        "",
        (.focusHistory | reverse[].nodeId)
    ' | {
        while read -r node && [[ $node ]]; do
            [[ ! $title || $(xtitle "$node") =~ $title ]] && nodes[$node]=
        done
        (( ${#nodes[@]} )) || return
        while (( ${#nodes[@]} > 1 )) && read -r node; do
            unset 'nodes[$node]'
        done
        node=("${!nodes[@]}")
        bspc node "$node" -f
    }
}

terminal() {
    local instance title focus_title columns lines hold
    if [[ $instance || $focus_title ]]; then
        class=alacritty instance="$instance" title="$focus_title" focus-window && return
    fi
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
            instance=irc title=weechat terminal autossh -M 0 -- -qt "$server_hostname" tmux -L weechat attach -d &;;
        editor)
            focus_title='- VIM$' terminal vim &;;
        web|browser)
            class=firefox focus-window || exec firefox &;;
        mail)
            class=thunderbird focus-window || exec thunderbird &;;
        files)
            class=thunar focus-window || exec thunar &;;
        music)
            exec rofi -show music;;
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
    lock)
        i3lock -c 000000;;
    quit)
        kill "$(< "$XDG_RUNTIME_DIR/bar.pid")" 2> /dev/null
        bspc quit;;
esac
