shopt -s nullglob

tmsu info &> /dev/null && tmsu=1

try_move() {
    local source=$1 destination=$2
    [[ -e $destination ]] && return 1
    printf '%s -> %s\n' "$source" "$destination"
    mv -n -- "$source" "$destination" &&
    if (( tmsu )); then
        tmsu repair --manual "$source" "$destination"
    fi
}

get_extension() {
    [[ ${1#.} =~ (\.([[:alpha:]][[:alnum:]]{,9}|7z))+$ ]] && printf '%s\n' "${BASH_REMATCH[0]}"
}

[[ -d $1 ]] || exit 1
dir=${1%/}
shift

files_in=()
for f in "$dir"/*; do
    [[ -f $f ]] && files_in+=("$f")
done

files_ex=()
for f do
    [[ $f == */* ]] || f=./$f
    [[ -f $f ]] && [[ ! ${f%/*} -ef $dir ]] && files_ex+=("$f")
done

(( n = ${#files_in[@]} + ${#files_ex[@]} ))
length=1
while (( n /= 10 )); do (( length++ )); done

name_regex='^([0-9]{1,'$length'})(\.|$)'
renamed=()
not_renamed=()

for f in "${files_in[@]}"; do
    name=${f##*/}
    if [[ $name =~ $name_regex ]]; then
        renamed[10#${BASH_REMATCH[1]}]=$f
    else
        not_renamed+=("$f")
    fi
done

files_ordered=("${renamed[@]}" "${not_renamed[@]}" "${files_ex[@]}")
pending_source=() pending_destination=()

for i in "${!files_ordered[@]}"; do
    source=${files_ordered[i]}
    name=${source##*/}
    extension=$(get_extension "$name")
    printf -v n '%0*d' "$length" "$(( i + 1 ))"
    destination=$dir/$n$extension
    if [[ -e $destination ]]; then
        if [[ ! $destination -ef $source ]]; then
            pending_source+=("$source")
            pending_destination+=("$destination")
        fi
    else
        try_move "$source" "$destination"
    fi
done

for (( i = ${#pending_source[@]} - 1; i >= 0; i-- )) do
    source=${pending_source[i]}
    destination=${pending_destination[i]}
    if ! try_move "$source" "$destination"; then
        printf 'cannot move %s: %s exists\n' "$source" "$destination" >&2
        exit 1
    fi
done
