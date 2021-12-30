shopt -s nullglob lastpipe

pidfile=$XDG_RUNTIME_DIR/bar.pid
[[ -e $pidfile ]] && kill "$(< "$pidfile")" 2> /dev/null
pkill -x lemonbar
echo "$$" > "$pidfile"

. config env

# Functions

desktop_label() case $1 in
    web) printf ;;
    mail) printf ;;
    chat) printf ;;
    files) printf ;;
    *) printf '∙';;
esac

escape() {
    local -n var=$1
    var=${var//\%/%%}
}

trunc() {
    local -n var=$1
    local max_length=$2
    if (( ${#var} > max_length )); then
        var=${var::max_length/2}…${var:${#var} - (max_length - 1)/2}
    fi
}

pad() {
    local -n var=$1
    var="  $var  "
}

pad_right() {
    local -n var=$1
    var="$var   "
}

icon_ramp() {
    local value=$1 index
    shift
    if [[ $1 == -u ]]; then
        shift
        index=$(( value*$#/100 + 1 ))
        (( index > $# )) && index=$#
        printf '%s\n' "${!index}"
    else
        while [[ $1 ]]; do
            if [[ ! $2 || $value -le $2 ]]; then
                printf '%s\n' "$1"
                return
            fi
            shift 2
        done
    fi
}

print_time() {
    local seconds=$1 minutes hours
    (( minutes = seconds / 60, seconds %= 60 ))
    (( hours = minutes / 60, minutes %= 60 ))
    (( hours )) && printf '%02d:' "$hours"
    printf '%02d:%02d\n' "$minutes" "$seconds"
}

debounce() {
    local delay=${1:-0.1} IFS=
    while read -r line; do
        while read -rt "$delay" line_; do
            line=$line_
        done
        printf '%s\n' "$line"
    done
}

cleanup_on_exit() {
    trap 'kill $(jobs -p) 2> /dev/null' EXIT
}

# Variables

battery=(/sys/class/power_supply/BAT*)
read -r default_layout < <(xkb-switch -l)
bold=3

xft_fonts=("siji:pixelsize=10" "${theme[font]}:size=${theme[fontSize]}" "${theme[font]}:bold:size=${theme[fontSize]}" "tewi:size=${theme[fontSize]}" "Biwidth:size=${theme[fontSize]}")
font_args=()
for f in "${xft_fonts[@]}"; do
    case $f in
        *siji*) offset=-2;;
        *Biwidth*) offset=-1;;
        *) offset=0;;
    esac
    font_args+=(-o "$offset" -f "$f")
done

#
# Data feed
#

cleanup_on_exit

{

    # Set up a builtin-only sleep function
    exec {sleep_fd}<> <(:)
    sleep() {
        read -rt "${1:-0}" -u "$sleep_fd"
    }

    # Toggle the clock display format on USR1
    trap 'echo Ctoggle' USR1

    # Toggle the battery display format on USR2
    trap 'echo Ptoggle' USR2

    cleanup_on_exit

    # WM info
    bspc subscribe report &

    # window title
    xtitle -sf 'T%s\n' | debounce 0.1 &

    # X keyboard layout
    {
        cleanup_on_exit
        xkb-switch -p
        xkb-switch -W
    } | sed -u 's/^/K/' &

    # clock
    while true; do
        printf 'C\n'
        sleep 1
    done &

    # systemd
    while true; do
        failed_units=()
        for user in '' --user; do
            systemctl $user list-units --failed --plain --no-legend
        done | while read -r unit _; do
            failed_units+=("${unit%.service}")
        done
        printf 'Y%s\n' "${failed_units[*]}"
        sleep 1
    done &

    # dunst
    while true; do
        paused=0
        if [[ $(timeout 0.1s dunstctl is-paused) == true ]]; then
            paused=1
        fi
        printf 'D%s\n' "$paused"
        sleep 1
    done &

    # power
    if [[ $battery ]]; then
        udevadm monitor -u -s power_supply |
        while read -r; do
            printf 'P\n'
        done &

        while true; do
            printf 'P\n'
            sleep 5
        done &
    fi

    # backlight
    if backlight=(/sys/class/backlight/*); (( ${#backlight[@]} )); then
        udevadm monitor -u -s backlight |
        while
            printf 'B%s\n' "$(backlight)"
            read -r
        do :; done &
    fi

    # sound
    stdbuf -oL alsactl monitor |
    while
        printf 'S%s\n' "$(volume)"
        read -r
    do :; done &

    # network
    ip -o monitor address route rule |
    while
        sleep 0.1
        parts=()
        ip -o address show up scope global |
        awk '!seen[$2]++ { print $2 }' |
        while read -r interface; do
            case $interface in
            en*|eth*)
                parts+=("D$interface");;
            wl*)
                ssid=
                iw dev "$interface" info | while read -r field value; do
                    if [[ $field == ssid ]]; then
                        printf -v ssid '%b' "$value"
                        break
                    fi
                done
                parts+=("L$interface,$ssid");;
            wg*)
                parts+=("G$interface");;
            esac
        done
        (IFS=:; printf 'N%s\n' "${parts[*]}")
        read -r
    do :; done &

    # music
    {
        cleanup_on_exit
        while echo; mpc idleloop; (( $? == 1 )); do sleep 1; done
    } |& while read -r; do
        song=
        song_file=$(mpc current -f '%file%')
        if [[ $song_file ]]; then
            song_artist=$(mpc current -f '%artist%')
            song_title=$(mpc current -f '%title%')
            if [[ $song_title ]]; then
                trunc song_title 30
                escape song_title
                song=$song_title
                if [[ $song_artist ]]; then
                    trunc song_artist 30
                    escape song_artist
                    song="%{T$bold}$song_artist%{T-} - $song"
                fi
            else
                trunc song_file 50
                escape song_file
                song=$song_file
            fi
            if mpc status | grep -qi 'random: *on'; then
                song=" $song"
            fi
            if mpc status | grep -qi 'repeat: *on'; then
                if mpc status | grep -qi 'single: *on'; then
                    song="$song (repeat1)"
                else
                    song="$song (repeat)"
                fi
            fi
        fi
        printf 'M%s\n' "$song"
    done &

    # wait
    until wait; do :; done

} |

#
# Parser
#

while read -rn 1 event; do
    case $event in
        W) # window manager
            wm=
            IFS=: read -ra parts
            for part in "${parts[@]}"; do
                type=${part::1}
                item=${part:1}
                if [[ ${type,,} == [fou] ]]; then
                    desktop=$item
                    item=$(desktop_label "$item")
                    pad item
                    item="%{A:wm focus-workspace $desktop:}%{A2:wm move-window-to-workspace $desktop:}$item%{A}%{A}"
                    if [[ $desktop =~ ^[[:alpha:]]+$ ]]; then
                        item="%{A3:wm go $desktop:}$item%{A}"
                    else
                        item="%{A3:wm focus-workspace $desktop;wm go terminal:}$item%{A}"
                    fi
                    case $type in
                        f|F) f=${theme[foregroundAlt]};;&
                        o|O) f=${theme[foreground]};;&
                        u|U) f=${theme[hot]};;&
                        f|o|u) item="%{F$f}$item%{F-}";;&
                        F|O|U) item="%{F${theme[background]}}%{B$f}$item%{B-}%{F-}";;&
                    esac
                    wm+=$item
                fi
            done
            ;;
        T) # title
            read -r title
            trunc title 50
            escape title
            if [[ $title ]]; then
                title=" $title"
                pad title
                title="%{A:bspc node -t ~floating:}%{A2:bspc node -c:}%{A3:bspc desktop -l next:}$title%{A}%{A}%{A}"
            fi
            ;;
        C) # clock
            read -r toggle
            if [[ $toggle == toggle ]]; then
                (( long_clock ^= 1 ))
            fi
            if (( long_clock )) ; then
                date_format="%a %-d %b %Y"
                time_format="%H:%M:%S"
            else
                date_format="%a %-d"
                time_format="%H:%M"
            fi
            printf -v clock " %($date_format %%{T$bold}$time_format%%{T-})T" -1
            pad_right clock
            clock="%{A:pkill -USR1 -P $$ -f $0 -o:}%{A3:wm go calendar:}$clock%{A}%{A}"
            ;;
        P) # power
            read -r toggle
            if [[ $toggle == toggle ]]; then
                (( long_battery ^= 1 ))
            fi
            status=$(< "$battery"/status)
            if [[ $status == Full ]]; then
                power=
            else
                (( percentage = $(< "$battery"/capacity) ))
                (( percentage > 100 )) && (( percentage = 100 ))
                icon=$(icon_ramp "$percentage" -u          )
                [[ $status == Charging ]] && icon+=
                power="$icon $percentage%%"
                if (( long_battery )); then
                    power+=" $status"
                    (( voltage = $(< "$battery"/voltage_now) / 1000 ))
                    if (( present_rate = $(< "$battery"/power_now) / voltage )); then
                        (( remaining_capacity = $(< "$battery"/energy_now) / voltage ))
                        if [[ $status == Charging ]]; then
                            (( full_capacity = $(< "$battery"/energy_full) / voltage))
                            (( seconds_left = 3600 * (full_capacity - remaining_capacity) / present_rate ))
                        elif [[ $status == Discharging ]]; then
                            (( seconds_left = 3600 * remaining_capacity / present_rate ))
                        fi
                    fi
                    (( seconds_left )) && power+=" $(print_time "$seconds_left")"
                fi
                (( percentage <= 10 )) && [[ $status != Charging ]] && power="%{F${theme[hot]}}$power%{F-}"
            fi
            pad_right power
            power="%{A:pkill -USR2 -P $$ -f $0 -o:}%{A3:power:}$power%{A}%{A}"
            ;;
        K) # keyboard
            read -r layout
            if [[ $layout == "$default_layout" ]]; then
                keyboard=
            else
                layout=${layout%%(*}
                escape layout
                keyboard=" $layout"
                pad_right keyboard
            fi
            ;;
        B) # backlight
            read -r percentage
            percentage=${percentage%.*}
            brightness="$(icon_ramp "$percentage"  10  50 ) $percentage%%"
            pad_right brightness
            brightness="%{A:light -S 100:}%{A3:light -S 0.8:}%{A4:backlight +:}%{A5:backlight -:}$brightness%{A}%{A}%{A}%{A}"
            ;;
        S) # sound
            IFS=: read -r percentage mute
            if [[ $mute == yes ]]; then
                sound=
            else
                sound="$(icon_ramp "$percentage"  10  50 ) $percentage%%"
            fi
            pad_right sound
            sound="%{A:wm go volume:}%{A3:volume toggle:}%{A4:volume +2:}%{A5:volume -2:}$sound%{A}%{A}%{A}%{A}"
            ;;
        N) # network
            IFS= read -r parts
            network=
            if [[ $parts ]]; then
                while read -rn 1 type; do case $type in
                    D) # wired
                        read -d : interface
                        network+=""
                        ;;
                    L) # wireless
                        IFS=, read -d : interface ssid
                        trunc ssid 15
                        escape ssid
                        network+="%{A:wm go wifi:}%{A}"
                        ;;
                    G) # wireguard
                        read -d : interface
                        wg=""
                        outDev4=$(ip -j route get 1.1.1.1 | jq -r '.[0].dev')
                        outDev6=$(ip -j route get 2606:4700:4700::1111 | jq -r '.[0].dev')
                        if [[ $outDev4 != "$interface" || $outDev6 != "$interface" ]]; then
                            wg="%{F${theme[hot]}}$wg%{F-}"
                        fi
                        wg="%{A3:wg-toggle:}$wg%{A}"
                        network+=$wg
                        ;;
                esac done <<< "$parts:"
                pad_right network
            fi
            ;;
        M) # music
            read -r song
            if [[ $song ]]; then
                pad_right song
                song="%{A2:mpc -q clear:}%{A3:mpc -q toggle:}%{A4:mpc -q volume +2:}%{A5:mpc -q volume -2:}%{A:wm go music:} %{A}%{A:music-notify:}$song%{A}%{A}%{A}%{A}%{A}"
            fi
            ;;
        Y) # systemd
            read -ra failed_units
            systemd=
            if (( ${#failed_units} )); then
                systemd="%{F${theme[hot]}}%{F-} ${failed_units[*]}"
            fi
            ;;
        D) # dunst
            read -r paused
            dunst=
            if (( paused )); then
                dunst="%{F${theme[hot]}}%{F-}"
            fi
            ;;
    esac

    alerts=$dunst$systemd
    [[ $alerts ]] && pad_right alerts

    left=$wm$title
    right=$song$mail$network$sound$brightness$im$keyboard$alerts$power$clock
    echo "%{l}$left%{r}$right"
done |

#
# Bar
#

lemonbar -g x"${theme[barHeight]}" \
         -a 255 \
         -B "${theme[background]}" \
         -F "${theme[foreground]}" \
         "${font_args[@]}" |

#
# Eval
#

while IFS= read -r command; do
    eval "$command" & disown
done &

# Set lemonbar to be just above the root window to prevent displaying over other windows
sleep 0.1s
xdo above -t "$(xdo id -n root)" -m -n lemonbar 2> /dev/null &

wait
