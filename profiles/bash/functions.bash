# Prompt

pwd_short() {
    set +x
    local pwd=$PWD user home component i prefix
    if [[ $pwd == "$HOME"?(/*) ]]; then
        printf '~'
        pwd=${pwd#"$HOME"}
    else
        while IFS= read -r user; do
            eval "home=~$user"
            if [[ $home == @(/home/*|/root|/var/*|/srv/*) && $pwd == "$home"?(/*) ]]; then
                printf '~%s' "$user"
                pwd=${pwd#"$home"}
                break
            fi
        done < <(compgen -u)
    fi
    while [[ $pwd == */* ]]; do
        component=${pwd%%/*}
        i=0
        while
            prefix=${component::++i}
            [[ $prefix == +(.) ]]
        do :; done
        printf %s/ "$prefix"
        pwd=${pwd#*/}
    done
    printf '%s\n' "$pwd"
}

prompt_char() {
    if [[ -v IN_NIX_SHELL || -v DIRENV_DIR ]]; then
        printf '\1%s\2$\1%s\2' "$(tput setaf 4)" "$(tput sgr0)"
    else
        printf '$'
    fi
}

hostname_pretty() {
    local -A kana=([wo]=ヲ [mo]=モ [fu]=フ [tsu]=ツ)
    if [[ $TERM != *linux* && -v 'kana[$HOSTNAME]' ]]; then
        echo "${kana[$HOSTNAME]}"
    else
        echo "$HOSTNAME"
    fi
}

# Files

cd() {
    if [[ $1 == +([^/]):* ]]; then
        local host=${1%%:*} path=${1#*:} path_escaped prefix rest
        if [[ $path == '~'* ]]; then
            IFS=/ read -r prefix rest <<< "$path"
            path_escaped=$prefix${rest:+/${rest@Q}}
        else
            path_escaped=${path@Q}
        fi
        mosh "$host" -- bash -c "cd $path_escaped && BASH_STARTUP=ls exec -l bash"
    else
        builtin cd "$@" && ls
    fi
}

mkcd() {
    mkdir -p "$@" && builtin cd "$@"
}

mvcd() {
    mv -i -- "$PWD" "$1" && builtin cd .
}

bck() {
    local f
    for f do
        cp -i -- "$f" "$f.bck"
    done
}

unbck() {
    local f
    for f do
        if [[ $f == *.bck ]]; then
            cp -i -- "$f" "${f%.bck}"
        else
            cp -i -- "$f.bck" "$f"
        fi
    done
}

flast() {
    local print_time=0 n=+1 o OPTIND OPTARG
    while getopts :tn: o; do case $o in
        t) print_time=1;;
        n) n=$OPTARG;;
    esac done; shift "$(( OPTIND - 1 ))"
    find "${@:-.}" -type f -printf '%T@/%P\0' | sort -znst / -k 1,1 | tail -zn "$n" |
    while IFS=/ read -rd '' time path; do
        (( print_time )) && printf '[%(%F %T)T] ' "${time%%.*}"
        printf '%s\n' "$path"
    done
}

# Disks

duh() {
    local lines=() total_size size file width=15 bar
    readarray -t lines < <(command du -xabd 1 "$@")
    read -r total_size _ <<< "${lines[-1]}"
    printf '%s\n' "${lines[@]::${#lines[@]}-1}" | sort -nrk 1,1 | while read -r size file; do
        bar=
        (( n = (width + 1) * (size - 1) / total_size))
        for (( i = 0; i < n; i++ )) do bar+='#'; done
        printf '%7s [%-*s] %s\n' "$(numfmt --to=iec-i --suffix=B "$size")" "$width" "$bar" "$file"
    done
}

mountl() {
    local label=$1
    sudo mkdir -p /mnt/"$label"
    sudo mount LABEL="$label" /mnt/"$label"
}

# Streams

grep() {
    local color
    if [[ -t 1 ]]; then
        color=always
    else
        color=never
    fi
    command grep --color="$color" "$@" | less -FR
    return "${PIPESTATUS[0]}"
}

sponge() {
    local tmp
    tmp=$(mktemp) || return 1
    cat > "$tmp"; cat -- "$tmp"
    rm -f -- "$tmp"
}

oneline() {
    local line
    while IFS= read -r line; do
        tput el
        printf '%s\r' "$line"
    done
    echo
}

unfold() {
    tr -s '[:space:]' '[ *]'
}

clipcmd_helper () {
    local cmd
    local -a lines
    read -r _ _ cmd < <(history 1)
    readarray lines < <(LC_ALL=en_US.UTF-8 eval "$cmd" 2>&1)
    printf %s "${lines[@]}"
    {
        printf '$ %s\n' "$cmd"
        printf %s "${lines[@]}"
    } | clip
}; alias clipcmd='clipcmd_helper # '

ix() {
    if (( $# )); then
        curl -fsSLF "f:1=@$1" ix.io
    else
        curl -fsSLF 'f:1=<-' ix.io
    fi | tee >(clip)
}

# SSH

sshesc() {
    local args=() interactive=0 cmd
    while (( $# )); do
        if [[ $1 == -i ]]; then
            interactive=1
        elif [[ $1 == -- ]]; then
            shift
            if (( interactive )); then
                cmd=$*
                args=(-qt "${args[@]}" bash -lic "${cmd@Q}")
            else
                args+=("${@@Q}")
            fi
            break
        else
            args+=("$1")
        fi
        shift
    done
    ssh "${args[@]}"
}

weechat_fifo() {
    ssh monade.li 'cat > ~/.weechat/weechat_fifo'
}

irc() {
    local cmd=$1
    shift
    case $cmd in
        np)
            mpc current -f $'*/me is now playing \x02%title%\x0f by \x02%artist%\x0f' | weechat_fifo;;
        grep)
            local where=$1
            [[ $where == */* ]] || where="$where/*"
            shift
            ssh monade.li "cd ~/irc-logs && rg -Np --color always ${*@Q} ''$where.weechatlog" | less -FR;;
        *)
            echo "Unknown action $cmd" >&2
            return 1;;
    esac
}

# Network

myip() {
    dig -4 +short @resolver1.opendns.com myip.opendns.com a
}

myip6() {
    dig -6 +short @resolver1.opendns.com myip.opendns.com aaaa
}

wg-toggle() {
    local interface=wg0
    if systemctl -q is-active wg-quick@"$interface"; then
        sudo systemctl stop wg-quick@"$interface"
    else
        sudo systemctl start wg-quick@"$interface"
    fi
}

wg-whitelist() {
    local arg=$1
    if [[ $arg != +([0-9]).+([0-9]).+([0-9]).+([0-9]) ]]; then
        arg=($(dig +short "$arg"))
    fi
    for ip in "${arg[@]}"; do
        sudo ip rule add from "$ip" lookup main
        sudo ip rule add to "$ip" lookup main
    done
}

# Misc

args() {
    printf '%d\n' "$#"
    if (( $# )); then
        printf '<%s> ' "$@"
        echo
    fi
}

count() {
    printf '%d\n' "$#"
}

remind() {
    local delay=$1
    shift
    {
        sleep "$delay"
        exec dunstify -i dialog-info -t 10000 "$*"
    } &> /dev/null & disown
}

insist() {
    local command=("$@")
    until "${command[@]}"; do sleep 0.1; done
}

with() {
    local args
    while read -rep "${PS1@P}$* " args; do
        history -s "$args"
        eval "$* $args"
    done
    echo
}

man() {
    if [[ $1 != -* && $2 == -* ]]; then
        command man -P "${MANPAGER:-less} -+i +'/^[[:space:]]*'${2@Q}" "$1"
    else
        command man "$@"
    fi
}

rfc() {
    local -A codes=([ascii]=20 [udp]=768 [ip]=791 [icmp]=792 [tcp]=793 [arp]=826 [ftp]=959 [dns]=1034 [dns2]=1035 [ipoac]=1149 [imap2]=1176 [md5]=1321 [irc]=1459 [imap4]=1730 [netiquette]=1855 [private]=1918 [pop3]=1939 [http1]=1945 [http]=1945 [keywords]=2119 [dhcp]=2131 [abnf]=2234 [tls1]=2246 [ipv6]=2460 [ipoac2]=2549 [irc2]=2810 [ircc]=2812 [ircs]=2813 [nat]=3022 [punycode]=3492 [utf8]=3629 [sasl]=4422 [sha]=4634 [smtp]=5321 [websocket]=6455 [oauth]=6749 [http2]=7540)
    local i
    for i do
        [[ -v 'codes[$i]' ]] && i=${codes[$i]}
        ${PAGER:-less} /usr/share/doc/rfc/txt/rfc"$i".txt
    done
}

mk() {
    local dir=$PWD
    until [[ -e $dir/Makefile ]]; do
        dir=$(dirname "$dir")
        [[ $dir == / ]] && return 1
    done
    make -f "$dir/Makefile" "$@"
}

# EFI

efibootorder() {
    local field value boot_order=() boot_entries=()
    while read -r field value; do
        if [[ $field == BootOrder: ]]; then
            IFS=, read -ra boot_order <<< "$value"
        elif [[ $field =~ ^Boot([0-9A-F]+) ]]; then
            boot_entries[16#${BASH_REMATCH[1]}]=$value
        fi
    done < <(efibootmgr)
    for i in "${boot_order[@]}"; do
        printf -- '- %s\n' "${boot_entries[16#$i]}"
    done
}

# Python

pyv() {
    local root=.
    until [[ -d $root/.venv ]]; do
        if [[ $root -ef / ]]; then
            return 1
        fi
        root+=/..
    done
    if (( $# )); then
        (. "$root"/.venv/bin/activate; "$@")
    else
        . "$root"/.venv/bin/activate
    fi
}

# Vultr

vultr_json() {
    vultr "$@" |
    jq -Rn '
        def fields: split("\t") | map(select(length > 0));
        input | fields | map(ascii_downcase | gsub(" "; "_")) as $keys |
        inputs | [$keys, fields] | transpose | map({(.[0]): .[1]}) | add'
}

vultr() {
    local args=() arg id
    local preset_5=(-p 201) preset_10=(-p 202) preset_20=(-p 203)
    local preset_archiso=(-o 159 --iso=547601) preset_ubuntu=(-o 270)
    [[ -v VULTR_API_KEY ]] || [[ -f ~/.vultr ]] && . ~/.vultr
    for arg do
        case $arg in
        @*)
            if read -r id < <(vultr_json server list | jq -r --arg name "${arg#@}" 'select(.name == $name).subid'); then
                args+=("$id")
                continue
            fi
            ;;
        ISO=*)
            if read -r id < <(vultr_json iso | jq -r --arg name "${arg#*=}" 'select(.filename == $name).isoid'); then
                args+=(-o 159 --iso="$id")
                continue
            fi
            ;;
        SCRIPT=*)
            if read -r id < <(vultr_json script list | jq -r --arg name "${arg#*=}" 'select(.name == $name).scriptid'); then
                args+=("$id")
                continue
            fi
            ;;
        REGION=*)
            if read -r id < <(vultr_json regions | jq -r --arg name "${arg#*=}" 'select((.name | ascii_downcase) == ($name | ascii_downcase)).dcid'); then
                args+=(-r "$id")
                continue
            fi
            ;;
        %*)
            local -n preset=preset_${arg#%}
            if [[ -v preset ]]; then
                args+=("${preset[@]}")
                continue
            fi
            ;;
        esac
        args+=("$arg")
    done
    command vultr "${args[@]}"
}
