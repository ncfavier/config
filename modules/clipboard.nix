{ lib, this, pkgs, ... }: with lib; {
  config = mkMerge [
    {
      environment.systemPackages = with pkgs; [
        xsel
        (writeShellScriptBin "clip" ''
          clipin() {
            if [[ -v DISPLAY ]]; then
              xsel -bi
            else
              printf '\e]52;c;%s\a' "$(base64)" >&2
            fi
          }

          clipout() { xsel -bo 2> /dev/null; }

          newline=0 edit=0 unfold=0
          while getopts :neu o; do case $o in
            n) newline=1;;
            e) edit=1;;
            u) unfold=1;;
          esac done
          shift "$(( OPTIND - 1 ))"

          if (( edit )); then
            tmpfile=$(mktemp) || exit
            clipout > "$tmpfile"
            ''${EDITOR:-vim} "$tmpfile"
            clipin < "$tmpfile"
            rm -f -- "$tmpfile"
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

    (mkIf this.isStation {
      hm = {
        home.packages = [ pkgs.clipster ];
        xdg.configFile."clipster/clipster.ini".text = ''
          [clipster]
          default_selection = CLIPBOARD
          history_size = 0
          extract_uris = no
          extract_emails = no
        '';
        xsession.windowManager.bspwm.startupPrograms = [ "clipster -d" ];
      };
    })
  ];
}
