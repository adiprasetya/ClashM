#!/system/bin/sh

DIR="${0%/*}"
. "$DIR/configuration"

# extracted from ( https://t.me/e58695/54 )
start_service() {
  if [[ ! -f "$BIN" ]]; then
    echo "error: core is missing."
    exit 1
  fi

  if [[ ! -f "$TEMPORARY" ]]; then
    echo "error: configuration file does not exist!"
    exit 1
  fi

  ERROR_LOG="$DATA/error.log"
  chmod -R 0755 "$BIN_DIR"
  "$BIN" -t -d "$DATA" -f "$TEMPORARY" > "$ERROR_LOG"
  if [[ "$?" != "0" ]]; then
    echo "error: configuration check failed!"
    echo "help: check $ERROR_LOG for clue, and re-check configuration file."
    exit 1
  fi

  date "+%A, %d %B %Y | %R %Z" > "$CORE_LOG_FILE"
  echo >> "$CORE_LOG_FILE"
  ulimit -SHn 1000000
  nohup "$BUSYBOX" setuidgid 0:3005 \
  "$BIN" -d "$DATA" -f "$TEMPORARY"  &>> "$CORE_LOG_FILE" &
  echo -n "$!" > "$PID_FILE"
  echo "info: core started."
  rm -f "$ERROR_LOG"
}

stop_service() {
  PID="$(cat "$PID_FILE")"
  kill -15 "$PID" &> /dev/null
  rm -f "$PID_FILE"
  rm -f "$TEMPORARY"
  echo "info: core stopped."
}


android_tun() {
  mkdir -p /dev/net
  if [[ ! -L /dev/net/tun ]]; then 
    ln -sf /dev/tun /dev/net/tun
  fi
}

merge_config() {
  if [[ ! -f "$BASE" ]]; then
    echo "info: config not merged."
    TEMPORARY="$CONFIG"
    return 0
  fi
  cp -f "$BASE" "$TEMPORARY"
  echo >> "$TEMPORARY"
  cat "$CONFIG" >> "$TEMPORARY"
}

hotspot() {
  device="$(awk '/device:/ {print $2}' "$TEMPORARY")"
  interface=(utun Meta $device)
  if [[ "$HOTSPOT" != "ACCEPT" ]]; then
    HOTSPOT="REJECT"
    echo "info: hotspot traffic rejected."
  fi
  for i in ${interface[@]}; do
    iptables -I FORWARD -o "$i" -j "$HOTSPOT"
    iptables -I FORWARD -i "$i" -j "$HOTSPOT"
    ip6tables -I FORWARD -o "$i" -j "$HOTSPOT"
    ip6tables -I FORWARD -i "$i" -j "$HOTSPOT"
  done
}


start() {
  local pid=`cat "$PID_FILE" 2> /dev/null`
  if (cat "/proc/$pid/cmdline" | grep -q "$BIN"); then
    echo "info: core has been started."
    exit 1
  fi

  android_tun
  merge_config
  start_service
  hotspot
}


case "$1" in
  start|s)
    start
   ;;
  stop|k)
    stop_service
   ;;
  *)
    echo "Usage: $0 {start|stop}"
   ;;
esac
