#!/system/bin/sh

DIR="${0%/*}"
. "$DIR/configuration"

wait_until_login() {
  # in case of /data encryption is disabled
  while [[ "$(getprop sys.boot_completed)" != "1" ]]; do
    sleep 1
  done

  # we doesn't have the permission to rw "/sdcard" before the user unlocks the screen
  local TEST_FILE="/sdcard/Android/.ClashM"
  while [[ ! -f "$TEST_FILE" ]]; do
    echo "true" > "$TEST_FILE"
    sleep 1
  done
  rm -f "$TEST_FILE"
}

start_service() {
  echo "true" > "$RUN_LOG"
  chmod 644 "$RUN_LOG"
  "$SCRIPTS/main.sh" start &> "$RUN_LOG"
}


main() {
  rm -f "$PID_FILE"
  chmod -R 0755 "$SCRIPTS"

  if [[ ! -f "$MODDIR/manual" ]]; then
    if [[ ! -f "$MODDIR/disable" ]]; then
      start_service
    fi
    inotifyd "$SCRIPTS/inotify.sh" "$MODDIR" &> /dev/null &
  fi
}


wait_until_login
main