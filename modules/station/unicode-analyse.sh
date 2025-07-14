input=$(zenity --entry --title=Unicode --text="Unicode string to analyse:")
if [[ $input ]]; then
    output=$(gucharmap -p "$input")
    zenity --info --icon=accessories-character-map --title=Unicode --text="$output" --no-markup
fi
