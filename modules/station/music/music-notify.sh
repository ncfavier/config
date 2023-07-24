shopt -s lastpipe

escape() {
    local -n s=$1 o=$1_esc
    o=${s//'\'/'\\'}
    o=${o//'&'/'&amp;'}
    o=${o//'<'/'&lt;'}
    o=${o//'>'/'&gt;'}
}

mpc current -f $'%artist%\n%album%\n%title%' | {
    IFS= read -r artist
    IFS= read -r album
    IFS= read -r title
}
[[ $title ]] || exit
mpc status | {
    read -r _
    read -r progress
}

if artUrl=$(playerctl -p mpd metadata mpris:artUrl 2> /dev/null); then
    artUrl=${artUrl#file://}
    printf -v artFile '%b' "${artUrl//%//\\x}"
    icon=(-I "$artFile")
else
    icon=(-i application-audio)
fi

id=0x1F3B5 # 🎵
escape album; escape title
dunstify "${icon[@]}" -r "$id" "$artist" "<i>$album_esc</i>\n$title_esc\n$progress"
