stty -ixon

set -b +H


PS1='\['$(tput sgr0)'\]'${SSH_CONNECTION+$(hostname_pretty) }'\['$(tput bold)'\]\w\['$(tput sgr0)'\] $(prompt_char) '
PS2='\['$(tput sgr0)'\]> '
PROMPT_COMMAND='printf "\\033]0;%s\\007" "${SSH_CONNECTION+$HOSTNAME:}$(pwd_short)"'

if [[ $TERM != *linux* ]]; then
    trap '(( AT_PROMPT )) && AT_PROMPT=0 SECONDS_LAST=$SECONDS' debug
    PROMPT_COMMAND+=${PROMPT_COMMAND:+; }'(( SECONDS - SECONDS_LAST >= 3 )) && { (( SECONDS_ELAPSED = SECONDS - SECONDS_LAST )); printf \\a; }; AT_PROMPT=1'
fi

[[ -v BASH_STARTUP ]] && eval "$BASH_STARTUP"
