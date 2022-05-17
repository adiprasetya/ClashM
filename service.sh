#!/system/bin/sh

MODDIR="/data/adb/modules/REPLACE"
SCRIPTS="$MODDIR/scripts"

until [[ $(getprop sys.boot_completed) -eq 1 ]] ; do
  sleep 3
done
${SCRIPTS}/start.sh

