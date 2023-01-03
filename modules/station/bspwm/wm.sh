shopt -s lastpipe

. config env

die() {
    echo "$@" >&2
    exit 1
}

focus-window() {
    local node wm_data=$(bspc wm -d)
    local -A nodes=()
    jq <<< "$wm_data" -r --arg class "$class" --arg instance "$instance" '
        (
            .monitors[].desktops[].root//empty |
            recurse(.firstChild//empty, .secondChild//empty) |
            select(.client != null) |
            select($class == "" or (.client.className | test("^(\($class))$"; "i"))) |
            select($instance == "" or (.client.instanceName | test("^(\($instance))$"; "i"))) |
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

get-workspaces() {
    readarray -t workspaces < <(bspc query --desktops --names "$@")
    n=0
    for w in "${workspaces[@]}"; do
        (( w > n )) && (( n = w ))
    done
}

renumber-workspaces() {
    get-workspaces
    local i=1 new_workspaces=()
    for w in "${workspaces[@]}"; do
        if (( w )); then
            new_workspaces+=("$((i++))")
        else
            new_workspaces+=("$w")
        fi
    done
    bspc monitor -d "${new_workspaces[@]}"
}

terminal() {
    if [[ $class || $focus_title ]]; then
        class="$class" title="$focus_title" focus-window && return
    fi
    . /etc/set-environment # reset PATH
    exec alacritty \
        ${class:+--class "$class"} \
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
    app=$1
    shift
    case $app in
        term|terminal)
            terminal "$@" &;;
        chat|irc)
            class=irc lines=100 columns=140 terminal mosh -- "$server_hostname" tmux -L weechat attach -d &;;
        editor)
            focus_title='- N?VIM$' terminal vim &;;
        web|browser)
            class='firefox|chromium-browser' focus-window || exec firefox &;;
        mail)
            class=thunderbird focus-window || exec thunderbird &;;
        files)
            class='thunar|dolphin' focus-window || exec thunar &;;
        music)
            exec rofi -show music;;
        video)
            class='mpv|feh' focus-window;;
        volume)
            class=pavucontrol focus-window || exec pavucontrol &;;
        cal|calendar)
            class=calendar title=calendar columns=64 lines=9 hold=1 terminal cal -3 &;;
        wifi)
            class=wpa_gui focus-window || exec wpa_gui &;;
        emoji)
            rofi_args=(-theme-str 'configuration { font: "sans 14"; }')
            exec rofimoji --selector-args "${rofi_args[*]@Q}";;
        *)
            die "unknown application $app";;
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
    remove-workspace)
        get-workspaces --desktop '.!occupied'
        if (( n )); then
            bspc desktop "$n" -r
            renumber-workspaces
        fi;;
    add-workspace)
        get-workspaces
        bspc monitor -a "$((n + 1))"
        bspc desktop -f "$((n + 1))";;
    lock)
        i3lock -c 000000;;
    quit)
        kill "$(< "$XDG_RUNTIME_DIR/bar.pid")" 2> /dev/null
        bspc quit;;
    *)
        die "no such command: $cmd";;
esac
