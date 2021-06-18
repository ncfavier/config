# TODO make this an actual rofi script
shopt -s lastpipe nocasematch

dmenu() {
    rofi -dmenu -lines 15 -width 800 -i -matching fuzzy -sorting-method fzf "$@"
}

mpc() {
    command mpc -q "$@"
}

if (( $# )); then
    music=$(xdg-user-dir MUSIC)
    mpc clear
    for f do
        f=$(realpath "$f")
        mpc add "${f##"$music"/}"
    done
    mpc play
else
    filter=()
    declare -A filter_has=()

    mpc list artist | readarray -t artists

    {
        (( ${#artists[@]} > 1 )) && echo all
        printf '%s\n' "${artists[@]}"
    } |
    dmenu -p artist -format i/s |
    IFS=/ read -r index artist || exit 1

    if (( ${#artists[@]} == 1 || index > 0 )); then
        filter+=(artist "$artist")
        filter_has[artist]=1
    fi

    mpc list album "${filter[@]}" | readarray -t albums

    {
        (( ${#albums[@]} > 1 )) && echo all
        printf '%s\n' "${albums[@]}"
    } |
    dmenu -p album -format i/s |
    IFS=/ read -r index album || exit 1

    if (( ${#albums[@]} == 1 || index > 0 )); then
        filter+=(album "$album")
        filter_has[album]=1
    fi

    mpc clear

    if (( ${#filter[@]} )); then
        mpc findadd "${filter[@]}"
    else
        mpc add /
    fi

    format='%title%|%file%'
    no_filter=
    if [[ -v 'filter_has[album]' ]]; then
        format='[%track% - ]'$format
    elif [[ -v 'filter_has[artist]' ]]; then
        format='[%album% - ]'$format
    else
        format='[%artist% - ]'$format
        no_filter=1
    fi

    {
        (( no_filter )) && echo random
        mpc playlist -f "$format"
    } |
    dmenu -p song -format d |
    read -r index || exit 1

    (( no_filter && index-- ))

    if (( no_filter && index == 0 )); then
        mpc shuffle
        mpc play
    else
        mpc play "$index"
    fi
fi
