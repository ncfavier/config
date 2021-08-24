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

# too slow
# thumbnail=$(dbus-gen-thumbnails -s large "$(xdg-user-dir MUSIC)/$file"

file=$(xdg-user-dir MUSIC)/$file
read -r hash _ < <(gio info "$file" | awk '$1 == "uri:" { printf("%s", $2) }' | md5sum)
thumbnail=$XDG_CACHE_HOME/thumbnails/large/$hash.png

if [[ ! -r $thumbnail ]]; then
    thumbnail=$(mktemp --suffix .png) || exit
    trap 'rm -f "$thumbnail"' exit
    ffmpegthumbnailer -i "$file" -o "$thumbnail" -s 256 -m
fi

id=0x1F3B5 # 🎵
dunstify -I "$thumbnail" -r "$id" "$artist" "<i>$album</i>\n$title\n$progress"
