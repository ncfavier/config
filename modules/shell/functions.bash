ask() {
    local prompt=$1 default=${2:-y}
    read -rp "$prompt " answer
    answer=${answer:-$default}
    answer=${answer,,}
    [[ $answer == y* ]]
}

compreply() {
    local completion
    while IFS= read -r completion; do
        COMPREPLY+=("$completion")
    done < <(compgen "$@" -- "$cur")
}

complete_alias() { # completion function for aliases
    local alias_name=$1
    local function_name=_alias_$alias_name
    shift 1
    local cmd=$1
    eval "$function_name() {
        local c i
        COMP_WORDS=( ${*@Q} \"\${COMP_WORDS[@]:1}\" )
        (( COMP_CWORD += $# - 1 ))
        _completion_loader $cmd
        read -ra c < <(complete -p $cmd)
        for (( i = 0; i < \${#c[@]}; i++ )) do
            if [[ \${c[i]} == -F ]]; then
                \"\${c[i+1]}\"
                break
            fi
        done
    }"
    complete -F "$function_name" "$alias_name"
}

diff-json() {
    local old new
    old=$(mktemp --suffix .old)
    new=$(mktemp --suffix .new)
    jq -M . "$1" > "$old"
    jq -M . "$2" > "$new"
    diff "$old" "$new"
    rm -f "$old" "$new"
}

cat() { # cat directories to list them
    if (( $# == 1 )) && [[ -d $1 ]]; then
        ll "$1"
    else
        command cat "$@"
    fi
}

cd() { # ls after cd
    builtin cd "$@" &&
    if [[ -t 1 ]] && (( ${#FUNCNAME[@]} == 1 )); then ls; fi
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

rm() ( # rm, but more resilient to completion failures
    shopt -s nullglob extglob
    for arg do
        if [[ $arg != -* && $arg != */ && ! -L $arg && -d $arg ]] && matches=("$arg"!()) && (( ${#matches[@]} )); then
            ask "do you really want to remove '$arg'? (add a / to dismiss)" n || return 1
        fi
    done
    exec rm "$@"
)

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

# grep() { # page output
#     local args=()
#     [[ -t 1 ]] && args+=(--color=always)
#     command grep "${args[@]}" "$@" | less
#     return "${PIPESTATUS[0]}"
# }
#
# rg() { # page output
#     local args=()
#     [[ -t 0 ]] && args+=(--line-number)
#     [[ -t 1 ]] && args+=(--color always --heading)
#     command rg "${args[@]}" "$@" | less
#     return "${PIPESTATUS[0]}"
# }

sponge() {
    local tmp
    tmp=$(mktemp) || return
    cat > "$tmp"
    cat < "$tmp"
    rm -f -- "$tmp"
}

oneline() { # displays a stream on a single updating line
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

unansi() {
    sed 's/\x1b\[[0-9;]*m//g' "$@"
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

sshesc() { # ssh opts -- argv...
    local arg args=()
    while (( $# )); do
        arg=$1
        shift
        if [[ $arg == -- ]]; then
            break
        fi
        args+=("$arg")
    done
    ssh "${args[@]}" -- "${*@Q}"
}
complete_alias sshesc ssh

weechat_fifo() {
    . config env
    ssh "$server_hostname" '. config env; cat > "$weechat_fifo"'
}

irg() ( # search IRC logs
    shopt -s extglob
    . config env
    builtin cd "${synced[irc-logs]}" || return
    local interleave=
    if [[ $1 == -i ]]; then
        interleave=1
        shift
    fi
    local where=${1%%+(/)}
    where=${where/\#/+(\#)}
    shift
    (( $# )) || set -- '^'
    command rg --color always -N ${interleave:+-H --no-context-separator} --no-heading --field-context-separator=$'\t' --field-match-separator=$'\t' --sort path "$@" $where |
    if (( interleave )); then sort -s -b -t$'\t' -k2,2; else cat; fi |
    less
)
_irg() {
    if (( COMP_CWORD == 1 )); then
        . config env
        readarray -t COMPREPLY < <(compgen -f "${synced[irc-logs]}/$2")
        if (( ${#COMPREPLY[@]} == 1 )) && [[ -d ${COMPREPLY[0]} ]]; then
            COMPREPLY[0]+=/
            compopt -o nospace
        fi
        COMPREPLY=("${COMPREPLY[@]#"${synced[irc-logs]}"/}")
    fi
}
complete -F _irg irg

myip() { # print my public IPs
    myipv4
    myipv6
}
myipv4() {
    dig -4 +short @resolver1.opendns.com myip.opendns.com A
}
myipv6() {
    dig -6 +short @resolver1.opendns.com myip.opendns.com AAAA
}

man() { # man foo -bar
    if [[ $1 != -* && $2 == -* ]]; then
        command man -P "${MANPAGER:-less} -+i +'/^[[:space:]]*'${2@Q}" "$1"
    else
        command man "$@"
    fi
}

declare -A rfc_numbers=([ascii]=20 [udp]=768 [ip]=791 [icmp]=792 [tcp]=793 [arp]=826 [ftp]=959 [dns]=1034 [dns2]=1035 [ipoac]=1149 [imap2]=1176 [md5]=1321 [irc]=1459 [imap4]=1730 [netiquette]=1855 [private]=1918 [pop3]=1939 [http1]=1945 [http]=1945 [keywords]=2119 [dhcp]=2131 [abnf]=2234 [tls1]=2246 [ipv6]=2460 [ipoac2]=2549 [irc2]=2810 [ircc]=2812 [ircs]=2813 [nat]=3022 [punycode]=3492 [utf8]=3629 [sasl]=4422 [sha]=4634 [smtp]=5321 [websocket]=6455 [oauth]=6749 [http2]=7540)
rfc() {
    local n=$1
    [[ -v 'rfc_numbers[$n]' ]] && n=${rfc_numbers[$n]}
    curl -fsSL https://www.ietf.org/rfc/rfc"$n".txt | sponge | less
}
complete -W "${!rfc_numbers[*]}" rfc

xcompose() { # print the path to the system-wide XCompose file
    echo "$(pkgs xorg.libX11)/share/X11/locale/en_US.UTF-8/Compose"
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
        exec dunstify -i dialog-information -t 10000 "$*"
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

nix-build() {
    command nix-build --log-format bar-with-logs "$@"
}

nix-shell() {
    history -a
    command nix-shell --log-format bar-with-logs "$@"
    history -n
}

nix-build-delete() { # useful for running NixOS tests
    sudo nix-store --delete --ignore-liveness "$(nix-build --no-out-link "$@")"
}
complete_alias nix-build-delete nix-build

nbe() {
    local expr=$1
    shift
    nix-build -E "with import ./. {}; $expr" "$@"
}

nix-time() { # get a lower bound on the build time of a derivation (best if build wasn't interrupted) https://github.com/NixOS/nix/issues/1710
    local drv name prefix log birth mod
    drv=$(nix show-derivation "$1" | jq -r 'keys[0]')
    [[ $drv == /nix/store/* ]] || return
    name=${drv#/nix/store/} prefix=${name::2}
    log=(/nix/var/log/nix/drvs/$prefix/${name#"$prefix"}*)
    [[ -e $log ]] || return
    read -r birth mod < <(stat -c '%W %Y' "$log")
    python -c "import datetime; print(datetime.timedelta(seconds=$((mod - birth))))"
}
complete_alias nix-time nix show-derivation

nix-closure-size() {
    nix path-info -rsSh "$@"
}

nix-clear-cache() {
    rm ~/.cache/nix/binary-cache-v*.sqlite*
    sudo sh -c 'rm ~/.cache/nix/binary-cache-v*.sqlite*'
}

pkgs() {
    config bld pkgs."$1" --no-out-link
}
complete_alias pkgs nix build -f /etc/nixpkgs

drv() {
    nix show-derivation "$@" | if [[ -t 1 ]]; then
        less
    else
        jq -r 'keys[0]'
    fi
}

what() {
    local p=$(type -P "$1")
    realpath "${p:-$1}"
}
complete -c what

nix-locate-program() {
    nix-locate --minimal --type x --type s --whole-name --at-root --top-level /bin/"$1"
}

fdnp() {
    fd -L "$@" $NIX_PROFILES
}

hm() {
    if (( ! $# )); then
        set -- status
    fi
    if [[ $1 == log ]]; then
        shift
        journalctl -u home-manager-"$USER".service "${@--e}"
    else
        sudo systemctl "$@" home-manager-"$USER".service
    fi
}
complete_alias hm systemctl

pr() {
    NO_ALARM=1
    local origin
    origin=$(git remote get-url origin) || return
    if [[ $origin == *'github.com'* ]]; then
        gh pr create --web
    elif [[ $origin == *'gitlab.com'* ]]; then
        glab mr create --web --push --fill
    else
        echo "unknown repository type"
        return 1
    fi
}

command_not_found_handle() {
    local IFS=$' \t\n'
    if [[ $1 == *@* ]]; then # [user]@host as a shorthand for ssh user@host
        local host=${1#@}
        shift
        if (( $# )); then
            sshesc -qt "$host" -- bash -ilc "${*@Q}"
        else
            ssh -q "$host"
        fi
    else # look for a package providing the command in nixpkgs
        local pkgs=() i n action
        printf '%s\n' "$1: command not found" >&2
        if [[ -t 1 ]] && command -v nix-locate > /dev/null && {
            readarray -t pkgs < <(nix-locate-program "$1")
            (( n = ${#pkgs[@]} ))
        }; then
            echo "It is provided by the following attributes:"
            for (( i = 0; i < n; i++ )); do
                pkgs[i]=${pkgs[i]%.out}
                printf '%*d %s\n' "${#n}" "$((i+1))" "${pkgs[i]}"
            done
            if read -p "? " action && [[ $action =~ ^([0-9]*)([rsi]?)$ ]]; then
                i=${BASH_REMATCH[1]:-1}
                action=${BASH_REMATCH[2]:-s}
                if (( 1 <= i && i <= n )); then
                    case $action in
                    r)
                        nix-shell -p "${pkgs[i-1]}" --command "$*";;
                    s)
                        history -a
                        nix-shell -p "${pkgs[i-1]}";;
                    i)
                        nix-env -iA "pkgs.${pkgs[i-1]}";;
                    esac
                    return
                fi
            fi
        fi
        return 127
    fi
}
