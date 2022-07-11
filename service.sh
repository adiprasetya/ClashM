#!/system/bin/sh

MODDIR="/data/adb/modules/MODID"
SCRIPTS="$MODDIR/scripts"

until [[ $(getprop sys.boot_completed) -eq 1 ]] ; do
  sleep 3
done
"$SCRIPTS/start.sh"

