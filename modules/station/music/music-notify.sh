shopt -s lastpipe

escape() {
    local -n s=$1 o=$1_esc
    o=${s//'\'/'\\'}
    o=${o//'&'/'&amp;'}
    o=${o//'<'/'&lt;'}
    o=${o//'>'/'&gt;'}
}

mpc current -f $'%file%\n%artist%\n%album%\n%title%' | {
    IFS= read -r file
    IFS= read -r artist
    IFS= read -r album
    IFS= read -r title
}
[[ $file ]] || exit
mpc status | {
    read -r _
    read -r progress
}

file=$(xdg-user-dir MUSIC)/$file
thumbnail=$(mktemp --suffix .png) || exit
trap 'rm -f "$thumbnail"' exit
if ffmpegthumbnailer -i "$file" -o "$thumbnail" -s 500 -m; then
    icon=(-I "$thumbnail")
else
    icon=(-i application-audio)
fi

id=0x1F3B5 # 🎵
escape album; escape title
dunstify "${icon[@]}" -r "$id" "$artist" "<i>$album_esc</i>\n$title_esc\n$progress"
