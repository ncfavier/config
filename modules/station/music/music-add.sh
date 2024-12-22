shopt -s nullglob lastpipe

die() {
    (( $# )) && printf '%s\n' "$1" >&2
    exit 1
}

ask() { # TODO get this from functions.bash
    local prompt=$1 default=${2:-y}
    read -rp "$prompt " answer
    if [[ $answer ]]; then echo; else answer=$default; fi
    answer=${answer,,}
    [[ $answer == y ]]
}

destdir=$(xdg-user-dir MUSIC)
cover_maxsize=800
preserve_mtime=0

if [[ $1 == -n ]]; then
    # Normalise
    cd "$destdir" || exit
    for f in *.mp3; do
        n=$(ffprobe -loglevel error -show_entries format_tags -print_format json "$f" |
            jq -r '.format.tags | "\(.artist) - \(.album)\(if .track then " - \(.track)" else "" end) - \(.title).mp3" | gsub("[\"\\/:*?<>|]"; "_")')
        [[ $f != "$n" ]] && mv -i "$f" "$n"
    done
    exit
elif [[ $1 == -k ]]; then
    preserve_mtime=1
    shift
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
        yt-dlp -x --audio-format mp3 -o "$srcdir/%(playlist_index)s - %(title)s.%(ext)s" "$src" || die "Failed to download audio files."
        printf '\a'
    elif [[ -r $src ]]; then
        if [[ ${src%/*} -ef $destdir ]]; then cmd=(mv); else cmd=(cp --preserve=timestamps); fi
        "${cmd[@]}" -t "$srcdir" -- "$src"
    else
        die "File not found or not readable: $src"
    fi

    for srcfile in "$srcdir"/*; do
        basename=${srcfile##*/}

        if ask "Include '$basename' (or edit with Audacity)? [Y/e/n]"; then
            files+=("$srcfile")
        elif [[ $answer == e ]]; then
            editdir=$(mktemp --tmpdir="$tmpdir" -d "${basename%.*}-XXX")
            echo "Please save resulting file(s) under $editdir"
            echo "Starting Audacity..."
            awk -i inplace -v p="$editdir" '/^\[/{ok=0}/^\[ExportAudioDialog\]/{ok=1;print;print "Format=MP3";print "DefaultPath=" p;next}!(ok && /^DefaultPath|Format/){print}' "$XDG_CONFIG_HOME/audacity/audacity.cfg"
            audacity "$srcfile" &> /dev/null
            editedfiles=("$editdir"/*.mp3)

            if (( ${#editedfiles[@]} > 0 )); then
                files+=("${editedfiles[@]}")
            else
                files+=("$srcfile")
            fi
        fi
    done
done

(( ${#files[@]} > 0 )) || die "No files given."

artist= album= cover_src=
if [[ ${srcs[0]} == http?(s)://@(?(*.)bandcamp.com|soundcloud.com|music.youtube.com)/* ]]; then
    echo "Fetching album information..."
    info_json=$(yt-dlp -J "${srcs[0]}")
    jq -r '.entries[0]//. | .artist//.uploader, .album//.title, first(.thumbnails[].url | select(contains("googleusercontent")) | gsub("=w\\d+-h\\d+"; "=w800-h800"))//.thumbnail' <<< "$info_json" |
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
else
    cover_src=${cover_src/#'~'/"$HOME"}
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
        magick "$cover" -resize "${cover_maxsize}x${cover_maxsize}>" "$cover"
    fi
fi

use_tracks=
ask "Use track numbers? [Y/n]" && use_tracks=true

i=0
for file in "${files[@]}"; do
    basename=${file##*/}
    basename=${basename%.*}
    title=
    track=
    echo "File: $basename ($(( ++i ))/${#files[@]})"
    if [[ $info_json ]]; then
        jq -r --argjson i "$i" '(if has("entries") then .entries[] | select(.playlist_index == $i) else . end) | .track//.title' <<< "$info_json" |
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
    basename=${basename//[\"\\\/:*?<>|]/_}

    echo "Adding file to music directory..."
    destfile=$destdir/$basename.mp3
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
        "$destfile"
    if (( preserve_mtime )); then
        mtime=$(stat -c %Y "$file")
        touch -d "@$mtime" -- "$destfile"
    fi
done

mpc -q update

echo "Done!"
rm -r -- "$tmpdir"
trap - exit
