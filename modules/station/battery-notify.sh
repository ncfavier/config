shopt -s nullglob

print_time() {
  local seconds=$1 minutes hours
  (( minutes = seconds / 60, seconds %= 60 ))
  (( hours = minutes / 60, minutes %= 60 ))
  (( hours )) && printf '%02d:' "$hours"
  printf '%02d:%02d\n' "$minutes" "$seconds"
}

battery=(/sys/class/power_supply/BAT*)
status=$(< "$battery"/status)

(( capacity = $(< "$battery"/capacity) ))
if (( capacity > $fullAt )); then
  (( capacity = 100 ))
fi

# The kernel reports values in µV, µA, µAh and µWh (https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/include/linux/power_supply.h?h=v6.0.11#n22).
# Some firmware reports energy instead of charge, so we convert that to charge using voltage.
# Since bash doesn't have floating-point arithmetic, we work with milli- to minimise error.

(( voltage_now = $(< "$battery"/voltage_now) / 1000 )) # mV

if [[ -e $battery/current_now ]]; then
  current_now=$(< "$battery"/current_now)
  (( current_now = ${current_now#-} / 1000 )) # mA
else
  power_now=$(< "$battery"/power_now)
  (( current_now = ${power_now#-} / voltage_now )) # mA
fi

if [[ -e $battery/charge_now ]]; then
  (( charge_now = $(< "$battery"/charge_now) / 1000 )) # mAh
else
  (( charge_now = $(< "$battery"/energy_now) / voltage_now )) # mAh
fi

if [[ -e $battery/charge_full ]]; then
  (( charge_full = $(< "$battery"/charge_full) / 1000 )) # mAh
else
  (( charge_full = $(< "$battery"/energy_full) / voltage_now )) # mAh
fi

if (( current_now )); then
  if [[ $status == Charging ]]; then
    (( remaining_charge = charge_full - charge_now )) # mAh
    icon=battery-full-charging-symbolic
  else
    (( remaining_charge = charge_now )) # mAh
    icon=battery-full-symbolic
  fi
  (( remaining_time = 3600 * remaining_charge / current_now )) # s
fi

id=0x1F50B # 🔋
dunstify -i "$icon" -r "$id" "$status ($capacity%)" \
  "<b>Remaining time</b>: $(print_time "$remaining_time")\\n<b>Current</b>: $current_now mA"
