shopt -s nullglob

# If currently recording, stop recording

pidfile=$XDG_RUNTIME_DIR/shoot.pid

if { kill "$(< "$pidfile")"; } 2> /dev/null; then # redirect before the command substitution
    exit
fi

# Command line options

video=0 rename=0 crop=0 upload=0
while getopts :vncu o; do case $o in
    v) video=1;;
    n) rename=1;;
    c) crop=1;;
    u) upload=1;;
esac done
shift "$(( OPTIND - 1 ))"

# Target name

if (( video )); then
    thing=recording
    extension=.webm
else
    thing=screenshot
    extension=.png
fi

if (( $# )); then
    target=$1
elif (( rename )); then
    target=~/$(zenity --entry --title shoot --text "Name?") || exit
else
    n=1
    printf -v date '%(%F-%H%M%S)T' -1
    target=~/$thing-$date
    while [[ -e $target$extension ]]; do
        target=~/$thing-$date-$(( n++ ))
    done
fi

if [[ ${target##*/} != *.* ]]; then
    target+=$extension
fi

# Crop

offset= geometry=
if (( crop )); then
    if (( video )); then
        slop=$(slop -f '+%x,%y %wx%h') || exit 1
        read -r offset geometry <<< "$slop"
    else
        geometry=$(slop) || exit 1
    fi
fi

# Shoot

thumbnail_size=300
thumbnail=$(mktemp --suffix .png) || exit 1
trap 'rm -f "$thumbnail"' exit

if (( video )); then
    # First encoding: lossless, fast, matroska
    tmpvideo=$(mktemp -p ~ --suffix .mkv) || exit 1
    ffmpeg -hide_banner -y \
        ${geometry:+-video_size "$geometry"} \
        -framerate 30 \
        -f x11grab -i :0.0"$offset" \
        -c:v libx264 -crf 0 -preset ultrafast \
        "$tmpvideo" &
    echo "$!" > "$pidfile"
    wait
    rm -f "$pidfile"

    dunstify -t 10000 -i camera "Encoding..." "to $target" &

    # Second encoding: lossless, slow, webm
    ffmpeg -hide_banner -y \
        -i "$tmpvideo" \
        -c:v libvpx-vp9 -lossless 1 \
        "$target" &&
    rm -f "$tmpvideo"

    # Thumbnail
    ffmpegthumbnailer -i "$target" -o "$thumbnail" -s "$thumbnail_size"
else
    # Screenshot
    import -silent -window root ${geometry:+-crop "$geometry"} "$target"

    # Thumbnail
    convert "$target" -resize "${thumbnail_size}x${thumbnail_size}>" "$thumbnail"
fi

# Notify

if [[ $(dunstify -t 10000 -A open,open -I "$thumbnail" "${thing^} saved" "as $target") == open ]]; then
    exec xdg-open "$target" &> /dev/null
fi &

# Upload

if (( upload )); then
    exec upload -r "$target"
fi &

wait
