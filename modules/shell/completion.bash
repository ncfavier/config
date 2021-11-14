complete_alias() {
    local alias_name=$1
    local base_function=$2
    local function_name=_alias_$alias_name
    shift 2
    eval "
    $function_name() {
        COMP_WORDS=( ${*@Q} \"\${COMP_WORDS[@]:1}\" )
        (( COMP_CWORD += $(( $# - 1 )) ))
        _completion_loader $1
        $base_function
    }"
    complete -F "$function_name" "$alias_name"
}

# Aliases

complete -c C cxa cxan
complete -v dp
complete_alias s _systemctl systemctl
complete_alias u _systemctl systemctl --user
complete_alias j _journalctl journalctl
complete -c what

# Scripts

# _config() {
#
# }
# complete -F _config config
