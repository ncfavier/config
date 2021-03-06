shopt -s lastpipe

mpc current -f $'%file%\n%artist%\n%album%\n%title%' | {
    IFS= read -r file
    IFS= read -r artist
    IFS= read -r album
    IFS= read -r title
}
[[ $file ]] || exit

# too slow
# thumbnail=$(dbus-make-thumbnails -s large "$(xdg-user-dir MUSIC)/$file"

file=$(xdg-user-dir MUSIC)/$file
read -r hash _ < <(gio info "$file" | awk '$1 == "uri:" { printf("%s", $2) }' | md5sum)
thumbnail=$XDG_CACHE_HOME/thumbnails/large/$hash.png

if [[ ! -r $thumbnail ]]; then
    thumbnail=$(mktemp --suffix .png) || exit
    trap 'rm -f "$thumbnail"' exit
    ffmpegthumbnailer -i "$file" -o "$thumbnail" -s 256 -m
fi

id=0x$(printf '%s' 🎵 | iconv -f utf-8 -t utf-32be | xxd -p) # what do you mean 'overengineered'?
dunstify -I "$thumbnail" -r "$id" "$artist" "<i>$album</i>\n$title"
