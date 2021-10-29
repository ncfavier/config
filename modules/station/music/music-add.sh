shopt -s nullglob lastpipe

die() {
    (( $# > 0 )) && printf '%s\n' "$1" >&2
    exit 1
}

ask() {
    local prompt=$1 default=${2:-y} yn
    [[ ${default,,} == y* ]] && prompt+=" [Y/n]" || prompt+=" [y/N]"
    read -rp "$prompt " -n 1 yn
    if [[ $yn ]]; then echo; else yn=$default; fi
    [[ ${yn,,} == y* ]]
}

destdir=$(xdg-user-dir MUSIC)
cover_maxsize=800

if [[ $1 == -n ]]; then
    # Normalise
    cd "$destdir" || exit
    for f in *.mp3; do
        n=$(ffprobe -loglevel error -show_entries format_tags -print_format json "$f" |
            jq -r '.format.tags | "\(.artist) - \(.album)\(if .track then " - \(.track)" else "" end) - \(.title).mp3" | gsub("[\"\\/:*?<>|]"; "_")')
        [[ $f != "$n" ]] && mv -i "$f" "$n"
    done
    exit
fi

[[ -t 0 ]] || die "Not a terminal."

tmpdir=$(mktemp --tmpdir -d music-XXX) || die "Could not create temporary directory."
trap 'echo; echo "Files kept in $tmpdir"' exit

srcs=("$@")
(( ${#srcs[@]} > 0 )) || read -ep "Source URLs/paths? " -a srcs

files=()

for src in "${srcs[@]}"; do
    srcdir=$(mktemp --tmpdir="$tmpdir" -d src-XXX)

    if [[ $src =~ ^[[:alpha:]]+:// ]]; then
        echo "Downloading audio files from $src..."
        yt-dlp --ignore-config -x --audio-format mp3 -o "$srcdir/%(playlist_index)s - %(title)s.%(ext)s" --cookies-from firefox "$src" || die "Failed to download audio files."
        printf '\a'
    elif [[ -r $src ]]; then
        if [[ ${src%/*} -ef $destdir ]]; then cmd=mv; else cmd=cp; fi
        "$cmd" -t "$srcdir" -- "$src"
    else
        die "File not found or not readable: $src"
    fi

    for srcfile in "$srcdir"/*; do
        basename=${srcfile##*/}
        editedfiles=()

        if ask "Edit file $basename with Audacity?" n; then
            editdir=$(mktemp --tmpdir="$tmpdir" -d "${basename%.*}-XXX")
            echo "Please save resulting file(s) under $editdir"
            echo "Starting Audacity..."
            audacity "$srcfile" &> /dev/null
            editedfiles=("$editdir"/*.mp3)
        fi

        if (( ${#editedfiles[@]} > 0 )); then
            files+=("${editedfiles[@]}")
        else
            files+=("$srcfile")
        fi
    done
done

(( ${#files[@]} > 0 )) || die "No files given."

artist= album= cover_src=
if [[ ${srcs[0]} == http?(s)://*bandcamp.com/* ]]; then
    bandcamp_json=$(curl -fsSL "${srcs[0]}" | xmllint --html --xpath 'string(//script[@type="application/ld+json"])' - 2> /dev/null)
    jq -r '.byArtist.name, .name, (.image | if type == "array" then .[0] else . end)' <<< "$bandcamp_json" |
    { read -r artist; read -r album; read -r cover_src; }
fi

read -ep "Artist? " ${artist:+-i "$artist"} artist
read -ep "Album? [$artist] " ${album:+-i "$album"} album
album=${album:-$artist}
read -ep "Album cover? " ${cover_src:+-i "$cover_src"} cover_src

reuse_cover=
if [[ $cover_src == @ ]]; then
    reuse_cover=1
    cover_src=
fi

cover=
resize=1
if [[ $cover_src ]]; then
    cover=$(mktemp --tmpdir="$tmpdir" cover-XXX)

    if [[ $cover_src =~ ^[[:alpha:]]+:// ]]; then
        echo "Downloading album cover..."
        curl -fsSL "$cover_src" > "$cover" || die "Failed to download album cover."
    elif [[ -r $cover_src ]]; then
        if [[ $(file -b --mime-type "$cover_src") == image/* ]]; then
            cp -- "$cover_src" "$cover"
        else
            ffmpeg -loglevel error -nostdin -y -i "$cover_src" -map 0:v:0 -f image2 -c:v png "$cover" || die "Unable to extract album cover"
            resize=0
        fi
    else
        die "Album cover not found or not readable."
    fi

    if (( resize )); then
        echo "Resizing album cover..."
        convert "$cover" -resize "${cover_maxsize}x${cover_maxsize}>" "$cover"
    fi
fi

use_tracks=
ask "Use track numbers?" && use_tracks=true

i=0
for file in "${files[@]}"; do
    basename=${file##*/}
    basename=${basename%.*}
    title=
    track=
    echo "File: $basename ($(( ++i ))/${#files[@]})"
    if [[ $bandcamp_json ]]; then
        jq -r --argjson i "$i" '(if has("track") then .track.itemListElement[] | select(.position == $i).item else . end).name' <<< "$bandcamp_json" |
        read -r title
    else
        title=${basename#*' - '}
    fi
    read -ep "Title? " -i "$title" title
    [[ $use_tracks ]] && read -ep "Track number? " -i "$i" track

    ffprobe -loglevel error -show_entries format_tags -print_format json "$file" |
    jq -r '.format.tags | [(.artist, .album, .title, .track) + "\u0000"] | add' |
    for tag in artist album title track; do
        target=_
        [[ ${!tag} == @ ]] && target=$tag
        IFS= read -rd '' "$target"
    done
    basename="$artist - $album - ${track:+$track - }$title"
    basename=${basename//[\"\\\/:*?<>|]/_} # "]}# vim's parser is confused

    echo "Adding file to music directory..."
    ffmpeg -nostdin -loglevel error \
        -i "$file" \
        ${cover:+-i "$cover"} \
        -map 0:a ${reuse_cover:+-map 0:v:0} ${cover:+-map 1} \
        -c copy -fflags +bitexact -id3v2_version 3 \
        -map_metadata -1 \
        -metadata artist="$artist" \
        -metadata album="$album" \
        -metadata title="$title" \
        ${track:+-metadata track="$track"} \
        -metadata:s:v:0 comment='Cover (front)' \
        "$destdir/$basename.mp3"
done

mpc -q update

echo "Done!"
rm -r -- "$tmpdir"
trap - exit
