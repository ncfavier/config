# Functions and variables

die() {
    (( $# > 0 )) && printf '%s\n' "$1" >&2
    exit 1
}

tmpdir() {
    tmpdir=$(mktemp -d) || exit
    trap "rm -rf ${tmpdir@Q}" exit
}

build_url() {
    local file=$1
    jq -nr --arg host "$host" --arg file "$file" '"https://\($host)/\($file | split("/") | map(@uri) | join("/"))"'
}

extension() {
    [[ ${1#.} =~ (\.([[:alpha:]][[:alnum:]]{,9}|7z))+$ ]] && printf '%s\n' "${BASH_REMATCH[0]}"
}

. config env

host=up.$domain
uploads_dir=${syncedFolders[uploads]}
hash_length=6

# Parse command line arguments

remove=0 force=0 interactive=0
while getopts :l:rf o; do case $o in
    l)
        n=${OPTARG:-1}
        find "$uploads_dir" -type f -printf '%T@/%P\0' | sort -znst / -k 1,1 | tail -zn "$n" |
        while IFS=/ read -rd '' time path; do
            build_url "$path"
        done
        exit
        ;;
    r) remove=1;;
    f) force=1;;
esac done
shift "$(( OPTIND - 1 ))"
[[ -t 1 ]] && interactive=1
source=$1
destination=$2

# Figure out what the source is

if [[ ! $source || $source == - ]]; then
    tmpdir
    printf -v source '%s/stdin-%(%F-%H%M%S)T' "$tmpdir" -1
    cat > "$source"
elif [[ $source == +([[:alpha:]])://* ]]; then
    tmpdir
    (cd "$tmpdir" && curl -fsSLOJ "$source") || exit
    source=("$tmpdir"/*)
else
    source=$(realpath "$source")
    [[ -e $source ]] || die "source not found"
    [[ -f $source && -r $source ]] || die "source must be a readable regular file"
fi

# Figure out what the destination should be

basename=${source##*/}
extension=$(extension "$basename")
if [[ ! $destination ]]; then
    hash=$(openssl dgst -sha1 -binary "$source" | basenc --base64url)
    destination=${hash::hash_length}$extension
elif [[ $destination == '=' ]]; then
    destination=$basename
fi

#  Upload

rsync_opts=(--progress --protect-args --chmod=D755,F644)
(( remove )) && rsync_opts+=(--remove-source-files)
(( ! force )) && rsync_opts+=(--ignore-existing)
(( isServer )) && rsync_host= || rsync_host=$host:
rsync "${rsync_opts[@]}" "$source" "$rsync_host$uploads_dir/$destination" || exit # TODO use the uploads_dir of the server

# Report

url=$(build_url "$destination")
printf '%s\n' "$url" | tee >(clip)

if (( ! interactive )) && [[ $(dunstify -t 10000 -A open,open -i up "Uploaded $basename" "to $url") == open ]]; then
    exec xdg-open "$url" &> /dev/null
fi &
