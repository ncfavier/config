shopt -s lastpipe
IFS=

mpc current -f $'%file%\n%artist%\n%album%\n%title%' | {
    read -r file
    read -r artist
    read -r album
    read -r title
}
[[ $file ]] || exit

thumbnail=$(mktemp --suffix .png) || exit
trap 'rm -f "$thumbnail"' exit

# TODO dbus-get-thumbnail
ffmpegthumbnailer -i "$(xdg-user-dir MUSIC)/$file" -o "$thumbnail" -s 180 -m

dunstify -I "$thumbnail" -r 173952 "$artist" "<i>$album</i>\n$title"
