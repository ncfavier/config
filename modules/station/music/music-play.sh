mpc() {
    command mpc -q "$@"
}

music=$(xdg-user-dir MUSIC)
files=()
for f do
    f=$(realpath "$f")
    [[ $f == "$music"/* ]] && files+=("${f#"$music"/}")
done

if (( ${#files[@]} )); then
    mpc clear
    mpc add "${files[@]}"
    mpc play
fi
