. /run/current-system/sw/share/bash-completion/completions/git-prompt.sh

prompt_git() {
    local branch=$(__git_ps1 %s)
    if [[ $branch && $branch != @(master|main) ]]; then
        printf '@%s' "$(tput setaf 4)$branch$(tput sgr0)"
    fi
}

prompt_nix_shell() {
    if [[ -v IN_NIX_SHELL || -v DIRENV_DIR ]]; then
        printf +
    fi
}

declare -A katakana=([wo]=ヲ [mo]=モ [fu]=フ [tsu]=ツ)
if [[ $TERM != *linux* && -v 'katakana[$HOSTNAME]' ]]; then
    hostname_pretty=${katakana[$HOSTNAME]}
else
    hostname_pretty=$HOSTNAME
fi

PS1='\['$(tput sgr0)'\]'${SSH_CONNECTION+$hostname_pretty }'\['$(tput bold)'\]\w\['$(tput sgr0)'\]$(prompt_git) $(prompt_nix_shell)\$ '
PS2='\['$(tput sgr0)'\]> '

pwd_prompt_string='\W'
PROMPT_COMMAND+=${PROMPT_COMMAND:+;}'printf "\\033]0;%s\\007" "${SSH_CONNECTION+$hostname_pretty:}${pwd_prompt_string@P}"'

if [[ $TERM != *linux* ]]; then
    trap '(( AT_PROMPT )) && AT_PROMPT=0 SECONDS_LAST=$SECONDS' debug
    PROMPT_COMMAND+=${PROMPT_COMMAND:+;}'(( SECONDS - SECONDS_LAST >= 3 )) && { (( SECONDS_ELAPSED = SECONDS - SECONDS_LAST )); printf \\a; }; AT_PROMPT=1'
fi
