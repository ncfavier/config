{ pkgs, ... }: {
  programs.light.enable = true;

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "backlight" ''
      light() { command light -s sysfs/backlight/acpi_video0 "$@"; }
      if (( ! $# )); then
          light -G
      else case $1 in
          +) light -r -A 1;;
          -) light -r -U 1;;
      esac fi
    '')
  ];
}
