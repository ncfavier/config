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
        printf +
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

PS1='\['$(tput sgr0)'\]'${SSH_CONNECTION+$(hostname_pretty) }'\['$(tput bold)'\]\w\['$(tput sgr0)'\] $(prompt_char)\$ '
PS2='\['$(tput sgr0)'\]> '
PROMPT_COMMAND+=${PROMPT_COMMAND:+;}'printf "\\033]0;%s\\007" "${SSH_CONNECTION+$HOSTNAME:}$(pwd_short)"'

if [[ $TERM != *linux* ]]; then
    trap '(( AT_PROMPT )) && AT_PROMPT=0 SECONDS_LAST=$SECONDS' debug
    PROMPT_COMMAND+=${PROMPT_COMMAND:+;}'(( SECONDS - SECONDS_LAST >= 3 )) && { (( SECONDS_ELAPSED = SECONDS - SECONDS_LAST )); printf \\a; }; AT_PROMPT=1'
fi
