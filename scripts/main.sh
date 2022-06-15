#!/system/bin/sh

DIR="${0%/*}"
. "$DIR/configuration"

TERMUX="/data/data/com.termux/files/usr/bin"
if [[ -d "$TERMUX" ]]; then
  PATH="$PATH:$TERMUX"
fi

# extracted from ( https://t.me/e58695/54 )
start_service() {
  if [[ ! -f "${BIN}" ]]; then
    echo "err: core is missing."
    exit 1
  fi

  if [[ ! -f ${CONFIG} ]]; then
    echo "err: configuration file does not exist!"
    exit 1
  fi

  chmod 0755 ${BIN}
  ${BIN} -t -d ${DATA} > ${DATA}/error.log
  if [[ "$?" != "0" ]]; then
    echo "err: configuration check failed!"
    exit 1
  fi

  date "+%A, %d %B %Y | %R %Z" > ${CORE_LOG_FILE}
  echo >> ${CORE_LOG_FILE}
  ulimit -SHn 1000000
  nohup ${BUSYBOX} setuidgid 0:3005 \
  "${BIN}" -d "${DATA}" -f "${CONFIG}"  &>> ${CORE_LOG_FILE} &
  echo -n $! > ${PID_FILE}
  echo "info: core started."
  rm -f ${DATA}/error.log
}

stop_service() {
  kill -15 `cat ${PID_FILE}` &> /dev/null
  rm -f ${PID_FILE}
  echo "info: core stopped."
}


setup_tun() {
  mkdir -p /dev/net
  if [[ ! -L /dev/net/tun ]]; then 
    ln -sf /dev/tun /dev/net/tun
  fi
}

merger() {
  if [[ "$MERGE" == "true" ]]; then
    echo "info: force merge."
    cp -f "$BASE" "$CONFIG"
    echo >> "$CONFIG"
    cat "$PROXIES" >> "$CONFIG"
  fi
}

hotspot() {
  device="$(awk '/device:/ {print $2}' "$CONFIG")"
  interface=(utun Meta $device)
  if [[ "$HOTSPOT" == "true" ]]; then
    for i in ${interface[@]}; do
      iptables -I FORWARD -o "$i" -j ACCEPT
      iptables -I FORWARD -i "$i" -j ACCEPT
      ip6tables -I FORWARD -o "$i" -j ACCEPT
      ip6tables -I FORWARD -i "$i" -j ACCEPT
    done
  else
    for i in ${interface[@]}; do
      iptables -I FORWARD -o "$i" -j REJECT
      iptables -I FORWARD -i "$i" -j REJECT
      ip6tables -I FORWARD -o "$i" -j REJECT
      ip6tables -I FORWARD -i "$i" -j REJECT
    done
  fi
}


start() {
  local pid=`cat ${PID_FILE} 2> /dev/null`
  if (cat /proc/${pid}/cmdline | grep -q ${BIN}); then
    echo "info: core has been started."
    exit 1
  fi

  merger
  setup_tun
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
