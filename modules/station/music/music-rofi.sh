shopt -s lastpipe

mpc() {
    command mpc -q "$@"
}

opt() {
    printf '\0%s\x1f%s\n' "$1" "$2"
}

row() { # artist, album, index shouldn't be environment variables
    printf '%s\0info\x1f%s\n' "$1" "${artist@A} ${album@A} ${index@A}"
}

escape() {
    local -n s=$1 o=$1_esc
    o=${s//'&'/'&amp;'}
    o=${o//'<'/'&lt;'}
    o=${o//'>'/'&gt;'}
}

[[ $ROFI_INFO ]] && eval "$ROFI_INFO"

if (( ROFI_RETV == 0 )); then
    opt prompt artist
    opt markup-rows true
    opt no-custom true
    mpc list artist | readarray -t artists
    if (( ${#artists[@]} > 1 )); then
        artist=; row '*'
    fi
    for artist in "${artists[@]}"; do
        escape artist
        row "<b>$artist_esc</b>"
    done
elif [[ ! -v album ]]; then
    opt prompt album
    if [[ $artist ]]; then
        escape artist
        opt message "<b>$artist_esc</b>"
    fi
    mpc list album ${artist:+artist "$artist"} | readarray -t albums
    album=; row '*'
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
    mpc clear
    if [[ $artist || $album ]]; then
        mpc findadd ${artist:+artist "$artist"} ${album:+album "$album"}
    else
        mpc add /
    fi
    format='%title%|%file%'
    if [[ $album ]]; then
        format='[%track% - ]'$format
    elif [[ $artist ]]; then
        format='[%album% - ]'$format
    else
        format='[%artist% - ]'$format
    fi
    mpc playlist -f "$format" | readarray -t tracks
    if [[ ! $album ]] && (( ${#tracks[@]} > 1 )); then
        index=; row random
    fi
    index=1
    for track in "${tracks[@]}"; do
        row "$track"
        (( index++ ))
    done
else
    if [[ ! $index ]]; then
        mpc shuffle
        mpc play
    else
        mpc play "$index"
    fi
fi
