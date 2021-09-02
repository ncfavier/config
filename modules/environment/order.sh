shopt -s nullglob lastpipe

tmsu info &> /dev/null && tmsu=1

get_extension() {
    local f=${1##*/}
    if [[ ${f#.} =~ (\.[[:alnum:]]{1,10})+$ ]] &&
       [[ ${BASH_REMATCH[0]} =~ (\.[[:alnum:]]*[[:alpha:]][[:alnum:]]*)+$ ]]; then
        printf '%s\n' "${BASH_REMATCH[0]}"
    fi
}

dir=$(realpath -se "$1") || exit
if [[ ! -d $dir ]]; then
    echo "not a directory" >&2
    exit 1
fi
shift

# Gather files to order

inside=()
for f in "$dir"/*; do
    [[ -f $f ]] && inside+=("$f")
done

outside=()
for f do
    f=$(realpath -se "$f") || continue
    if [[ ! -f $f ]]; then
        echo "not a regular file: $f" >&2
        continue
    fi
    [[ ! ${f%/*} -ef $dir ]] && outside+=("$f")
done

# Sort filenames version-style

for f in "${inside[@]}"; do printf '%s\0' "$f"; done |
sort -zV |
readarray -d '' ordered
ordered+=("${outside[@]}")

# Rename files in two passes

rename() {
    local source=$1 destination=$2
    printf '%s -> %s\n' "$source" "$destination"
    mv -n -- "$source" "$destination" &&
    if (( tmsu )) && ! tmsu repair --manual "$source" "$destination"; then
        printf '%s -> %s\n' "$destination" "$source"
        mv -n -- "$destination" "$source"
        return 1
    fi
}

(( length = ${#inside[@]} + ${#outside[@]} ))
length=${#length} i=1
pending_source=() pending_destination=()
for source in "${ordered[@]}"; do
    printf -v destination '%0*d' "$length" "$(( i++ ))"
    destination=$dir/$destination$(get_extension "$source")
    [[ $source -ef $destination ]] && continue
    final_destination=$destination
    while [[ -e $destination ]]; do destination+=_; done
    rename "$source" "$destination" || exit
    if [[ $destination != "$final_destination" ]]; then
        pending_source+=("$destination")
        pending_destination+=("$final_destination")
    fi
done

for (( i = 0; i < ${#pending_source[@]}; i++ )) do
    source=${pending_source[i]} destination=${pending_destination[i]}
    if [[ -e $destination ]] || ! rename "$source" "$destination"; then
        echo "could not rename $source to $destination" >&2
        exit 1
    fi
done
