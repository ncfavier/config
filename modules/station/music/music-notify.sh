shopt -s lastpipe

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
ffmpegthumbnailer -i "$file" -o "$thumbnail" -s 350 -m

id=0x1F3B5 # 🎵
dunstify -I "$thumbnail" -r "$id" "$artist" "<i>$album</i>\n$title\n$progress"
