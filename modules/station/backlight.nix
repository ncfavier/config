{ pkgs, ... }: {
  programs.light.enable = true;

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "backlight" ''
      if (( ! $# )); then
          light -G
      elif [[ $1 =~ ^[+-]([0-9]*)$ ]]; then
          n=''${BASH_REMATCH[1]:-1}
          if [[ $1 == +* ]]; then
              light -A "$n"
          else
              light -U "$n"
          fi
      fi
    '')
  ];
}
