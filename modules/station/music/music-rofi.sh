shopt -s lastpipe

music_dir=$(xdg-user-dir MUSIC)

mpc() {
    command mpc -q "$@"
}

mpc_load() {
    mpc clear
    if [[ $1 == random ]]; then
        find -L "$music_dir" -maxdepth 1 -type f -mtime -500 -printf '%f\n' | mpc add
    elif [[ $artist || $album ]]; then
        mpc findadd ${artist:+artist "$artist"} ${album:+album "$album"}
    else
        mpc add /
    fi
}

opt() {
    printf '\0%s\x1f%s\n' "$1" "$2"
}

row() {
    printf '%s\0info\x1f%s\n' "$1" "${artist@A} ${album@A} ${index@A}"
}

escape() {
    local -n s=$1 o=$1_esc
    o=${s//'&'/'&amp;'}
    o=${o//'<'/'&lt;'}
    o=${o//'>'/'&gt;'}
}

[[ $ROFI_INFO ]] && eval "$ROFI_INFO"

if (( ROFI_RETV == 0 )); then # initial invocation
    opt prompt artist
    opt markup-rows true
    opt use-hot-keys true
    opt no-custom true
    mpc list artist | readarray -t artists
    if (( ${#artists[@]} > 1 )); then
        artist=; row '*'
    fi
    for artist in "${artists[@]}"; do
        escape artist
        row "<b>$artist_esc</b>"
    done
elif (( ROFI_RETV >= 10 )); then # custom keybinding: shuffle
    if [[ ! -v index ]]; then
        mpc_load random
    fi
    mpc shuffle
    mpc play
elif [[ ! -v album ]]; then
    opt prompt album
    if [[ $artist ]]; then
        escape artist
        opt message "<b>$artist_esc</b>"
    fi
    mpc list album ${artist:+artist "$artist"} | readarray -t albums
    if (( ${#albums[@]} > 1 )); then
        album=; row '*'
    fi
    for album in "${albums[@]}"; do
        escape album
        row "<i>$album_esc</i>"
    done
elif [[ ! -v index ]]; then
    opt prompt track
    opt markup-rows false
    escape artist; escape album
    if [[ $artist && $album ]]; then
        opt message "<b>$artist_esc</b> - <i>$album_esc</i>"
    elif [[ $artist ]]; then
        opt message "<b>$artist_esc</b>"
    elif [[ $album ]]; then
        opt message "<i>$album_esc</i>"
    fi
    format='%title%|%file%'
    if [[ $album ]]; then
        format='[%track% - ]'$format
    elif [[ $artist ]]; then
        format='[%album% - ]'$format
    else
        format='[%artist% - ]'$format
    fi
    mpc_load
    mpc playlist -f "$format" | readarray -t tracks
    index=1
    for track in "${tracks[@]}"; do
        row "$track"
        (( index++ ))
    done
else
    mpc play "$index"
fi
