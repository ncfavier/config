shopt -s lastpipe extglob

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
    readarray -t workspaces < <(bspc query --desktops --monitor focused --names "$@")
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
    bspc monitor focused -d "${new_workspaces[@]}"
}

terminal() {
    if [[ $class || $instance || $focus_title ]]; then
        class="$class" instance="$instance" title="$focus_title" focus-window && return
    fi
    . /etc/set-environment # reset PATH
    exec ghostty --launched-from=cli \
        ${class:+--class="$class"} \
        ${instance:+--x11-instance-name="$instance"} \
        ${new_instance:+--gtk-single-instance=false} \
        ${title:+--title="$title"} \
        ${columns:+--window-width="$columns"} \
        ${lines:+--window-height="$lines"} \
        ${hold:+--wait-after-command} \
        "$@"
}

launch() {
    new= not_new=1
    if [[ $1 == -n ]]; then
        shift
        new=1 not_new=
        focus-window() { return 1; }
    fi
    app=$1
    shift
    case $app in
        '')
            rofi -sidebar-mode -show-icons -modes drun,run,window -show drun &;;
        term|terminal|+([[:digit:]]))
            terminal ${*:+-e "$@"} &;;
        chat|irc)
            instance=irc lines=100 columns=140 terminal \
                --confirm-close-surface=false \
                -e mosh -- "$server_hostname" tmux -L weechat attach ${not_new:+-d} &;;
                # -o bell.command='{program = "notify-send", args = ["-i", "0", "-r", "0x1F4AC", "💬"]}' \
        editor)
            focus_title='- N?VIM$' terminal -e vim &;;
        web|browser)
            if (( new )); then
                bspc rule -a firefox -o desktop=focused
            fi
            class='firefox|chromium-browser' focus-window || exec firefox &;;
        mail)
            class=thunderbird focus-window || exec thunderbird &;;
        files)
            if (( new )); then
                bspc rule -a Thunar -o desktop=focused
            fi
            class='thunar|dolphin' focus-window || exec thunar &;;
        music)
            exec rofi -kb-custom-1 'Control+r' -show music;;
        video)
            class='mpv|feh|imv' focus-window;;
        volume)
            class=pavucontrol focus-window || exec pavucontrol &;;
        cal|calendar)
            instance=calendar title=calendar columns=64 lines=9 hold=1 terminal --confirm-close-surface=false -e sh -c 'sleep 0.1 &&cal -3' &;;
        wifi)
            class=wpa_gui focus-window || exec wpa_gui &;;
        emoji)
            rofi_args=(-theme-str "configuration { font: \"${theme[font]} 14\"; }")
            exec rofimoji --selector-args "${rofi_args[*]@Q}";;
        *)
            die "unknown application $app";;
    esac
}

cmd=$1
shift
case $cmd in
    launch)
        launch "$@";;
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
        bspc monitor focused -a "$((n + 1))"
        bspc desktop -f "$((n + 1))";;
    lock)
        i3lock -c 000000;;
    quit)
        kill "$(< "$XDG_RUNTIME_DIR/bar.pid")" 2> /dev/null
        bspc quit;;
    *)
        die "no such command: $cmd";;
esac
