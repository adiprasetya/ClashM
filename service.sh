#!/system/bin/sh

DIR="${0%/*}"
SCRIPTS="$DIR/scripts"

(
until [[ $(getprop sys.boot_completed) -eq 1 ]] ; do
  sleep 3
done
${SCRIPTS}/start.sh
)&

inotifyd "${SCRIPTS}/inotify.sh" "${DIR}" &> /dev/null &