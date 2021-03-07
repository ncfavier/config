{ pkgs, ... }: {
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "clip" ''
      clipin()  { ${pkgs.xsel}/bin/xsel -bi; }
      clipout() { ${pkgs.xsel}/bin/xsel -bo 2> /dev/null; }

      newline= edit= unfold=

      while getopts :neu o; do
          case $o in
              n) newline=1;;
              e) edit=1;;
              u) unfold=1;;
          esac
      done

      shift "$(( OPTIND - 1 ))"

      if (( edit )); then
          tmpfile=$(mktemp) || exit 1
          clipout > "$tmpfile"
          ${EDITOR:-nano} "$tmpfile"
          clipin < "$tmpfile"
          rm -- "$tmpfile"
      elif (( unfold )); then
          clipout | tr -s '[:space:]' '[ *]' | clipin
      else
          if [[ -t 0 ]] && (( ! $# )); then
              clipout | awk 1
          else
              if (( $# )); then
                  data=$*
              else
                  data=$(< /dev/stdin)
              fi
              if (( newline )); then
                  printf '%s\n' "$data"
              else
                  printf '%s' "$data"
              fi | clipin
          fi
      fi
    '')
  ];
}
