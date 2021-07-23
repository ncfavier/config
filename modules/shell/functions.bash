cat() { # cat directories to list them
    if (( $# == 1 )) && [[ -d $1 ]]; then
        ll "$1"
    else
        command cat "$@"
    fi
}

cd() { # ls after cd
    builtin cd "$@" && ls
}

mkcd() { # create a directory and move into it
    mkdir -p "$1" && builtin cd "$1"
}

mvcd() { # move the current working directory
    mv -i -- "$PWD" "$1" && builtin cd .
}

bck() { # backup
    local f
    for f do
        cp -ai -- "$f" "$f.bck"
    done
}
unbck() { # restore
    local f
    for f do
        [[ $f == *.bck ]] || f=$f.bck
        mv -i -- "$f" "${f%.bck}"
    done
}

readlinks() { # print a chain of symlinks
    local f=$1
    while [[ -L $f ]]; do
        printf '%s -> ' "$f"
        f=$(readlink "$f")
    done
    printf '%s\n' "$f"
}

flast() { # find the most recently modified files in a tree
    local print_time=0 n=+1 o OPTIND OPTARG
    while getopts :tn: o; do case $o in
        t) print_time=1;;
        n) n=$OPTARG;;
    esac done; shift "$(( OPTIND - 1 ))"
    find "${@:-.}" -type f -printf '%T@/%p\0' | sort -znst / -k 1,1 | tail -zn "$n" |
    while IFS=/ read -rd '' time path; do
        (( print_time )) && printf '[%(%F %T)T] ' "${time%%.*}"
        printf '%s\n' "$path"
    done
}

writeiso() { # write an ISO file to a block device
    local file=$1 device=$2
    sudo dd if="$file" of="$device" bs=1M oflag=sync status=progress
}

grep() {
    local args=()
    [[ -t 1 ]] && args+=(--color=always)
    command grep "${args[@]}" "$@" | less
    return "${PIPESTATUS[0]}"
}

rg() {
    local args=()
    [[ -t 1 ]] && args+=(-p)
    command rg "${args[@]}" "$@" | less
    return "${PIPESTATUS[0]}"
}

sponge() {
    local tmp
    tmp=$(mktemp) || return
    cat > "$tmp"
    cat < "$tmp"
    rm -f -- "$tmp"
}

oneline() { # displays a stream on a single line
    local line el=$(tput el)
    while IFS= read -r line; do
        printf '%s\r' "$el$line"
    done
    printf '\n'
}

unfold() { # collapse whitespace
    tr -s '[:space:]' '[ *]'
}

zton() {
    tr '\0' '\n'
}

# copy a command and its output to the clipboard
alias clipcmd='clipcmd_helper # '
clipcmd_helper() {
    local cmd
    local -a lines
    read -r _ _ cmd < <(history 1)
    readarray lines < <(LC_ALL=en_US.UTF-8 eval "$cmd" 2>&1)
    printf %s "${lines[@]}"
    {
        printf '$ %s\n' "$cmd"
        printf %s "${lines[@]}"
    } | clip
}

ix() { # upload to ix.io
    if (( $# )); then
        curl -fsSLF "f:1=@$1" ix.io
    else
        curl -fsSLF 'f:1=<-' ix.io
    fi | tee >(clip)
}

0x0() { # upload to 0x0.st
    if (( $# )); then
        curl -fsSLF "file=@$1" 0x0.st
    else
        curl -fsSLF 'file=@-' 0x0.st
    fi | tee >(clip)
}

weechat_fifo() {
    . config env
    ssh "$server_hostname" 'cat > ~/.weechat/weechat_fifo'
}

irg() {
    . config env
    rg -N "${@:2}" "${syncedFolders[irc-logs]}/$1"
}
_irg() {
    if (( COMP_CWORD == 1 )); then
        . config env
        readarray -t COMPREPLY < <(compgen -f "${syncedFolders[irc-logs]}/$2")
        if (( ${#COMPREPLY[@]} == 1 )) && [[ -d ${COMPREPLY[0]} ]]; then
            COMPREPLY[0]+=/
            compopt -o nospace
        fi
        COMPREPLY=("${COMPREPLY[@]#"${syncedFolders[irc-logs]}"/}")
    fi
}
complete -F _irg irg

myipv4() {
    dig -4 +short @resolver1.opendns.com myip.opendns.com A
}
myipv6() {
    dig -6 +short @resolver1.opendns.com myip.opendns.com AAAA
}
myip() { # print my public IPs
    myipv4
    myipv6
}

man() { # man foo -bar
    if [[ $1 != -* && $2 == -* ]]; then
        command man -P "${MANPAGER:-less} -+i +'/^[[:space:]]*'${2@Q}" "$1"
    else
        command man "$@"
    fi
}

rfc() {
    local -A numbers=([ascii]=20 [udp]=768 [ip]=791 [icmp]=792 [tcp]=793 [arp]=826 [ftp]=959 [dns]=1034 [dns2]=1035 [ipoac]=1149 [imap2]=1176 [md5]=1321 [irc]=1459 [imap4]=1730 [netiquette]=1855 [private]=1918 [pop3]=1939 [http1]=1945 [http]=1945 [keywords]=2119 [dhcp]=2131 [abnf]=2234 [tls1]=2246 [ipv6]=2460 [ipoac2]=2549 [irc2]=2810 [ircc]=2812 [ircs]=2813 [nat]=3022 [punycode]=3492 [utf8]=3629 [sasl]=4422 [sha]=4634 [smtp]=5321 [websocket]=6455 [oauth]=6749 [http2]=7540)
    local n=$1
    [[ -v 'numbers[$n]' ]] && n=${numbers[$n]}
    curl -fsSL https://www.ietf.org/rfc/rfc"$n".txt | sponge | less
}

args() {
    echo "$# arguments"
    if (( $# )); then
        printf '<%s> ' "$@"
        echo
    fi
}

count() {
    echo "$#"
}

remindme() {
    local delay=$1
    shift
    {
        sleep "$delay"
        exec dunstify -i dialog-info -t 10000 "$*"
    } &> /dev/null & disown
}

mk() ( # runs make using the closest makefile in the hierarchy
    local dir=$PWD
    shopt -s nullglob
    until files=("$dir"/@(GNUmakefile|makefile|Makefile)); (( ${#files[@]} )); do
        dir=$(dirname "$dir")
        [[ $dir == / ]] && return 1
    done
    make -f "${files[0]}" "$@"
)

pkgs() {
    nix-build '<nixpkgs>' --no-out-link -A "$@"
}
_pkgs() {
    local cur prev words cword
    _completion_loader nix-build
    _init_completion -n =:
    _nix_attr_paths 'import <nixpkgs>'
}
complete -F _pkgs pkgs

command_not_found_handle() {
    local attrs IFS=$' \t\n'
    if [[ $1 == *@* ]]; then
        ssh -qt "${1#@}" "${@:2}"
    else
        printf '%s\n' "$1: command not found" >&2
        if [[ -t 1 ]] && {
            readarray -t attrs < <(nix-locate --minimal --type x --type s --whole-name --at-root --top-level /bin/"$1")
            for (( i = 0; i < ${#attrs[@]}; i++ )); do
                attrs[i]=${attrs[i]%.out}
            done
            (( ${#attrs[@]} ))
        }; then
            echo "It is provided by the following attributes:"
            for attr in "${attrs[@]}"; do
                echo "  $attr"
            done
        fi
        return 127
    fi
}
