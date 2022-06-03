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
    echo "err: clash core is missing."
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

  echo "Date: $(date +%F)" > ${CORE_LOG_FILE}
  echo "Time: $(date +%R)" >> ${CORE_LOG_FILE}
  echo >> ${CORE_LOG_FILE}
  ulimit -SHn 1000000
  nohup ${BUSYBOX} setuidgid 0:3005 \
  "${BIN}" -d "${DATA}" -f "${CONFIG}"  &>> ${CORE_LOG_FILE} &
  echo -n $! > ${PID_FILE}
  echo "info: clash core started."
  rm -f ${DATA}/error.log
}

stop_service() {
  kill -15 `cat ${PID_FILE}` &> /dev/null
  rm -f ${PID_FILE}
  echo "info: clash core stopped."
}


tun_setup() {
  mkdir -p /dev/net
  if [[ ! -L /dev/net/tun ]]; then 
    ln -sf /dev/tun /dev/net/tun
    echo "info: tun setup for first time."
  fi
}

merger() {
  echo "info: merge config."
  cp -f "$BASE" "$CONFIG"
  echo >> "$CONFIG"
  cat "$PROXIES" >> "$CONFIG"
}

forward_device() {
  device="$(awk '/device/ {print $2}' "$CONFIG")"
  interface=(utun Meta $device)
  for i in ${interface[@]}; do
    iptables -I FORWARD -o "$i" -j ACCEPT
    iptables -I FORWARD -i "$i" -j ACCEPT
    ip6tables -I FORWARD -o "$i" -j ACCEPT
    ip6tables -I FORWARD -i "$i" -j ACCEPT
  done
  echo "info: tun interface forwarded."
}


start() {
  local pid=`cat ${PID_FILE} 2> /dev/null`
  if (cat /proc/${pid}/cmdline | grep -q ${BIN}); then
    echo "info: clash core has been started."
    exit 1
  fi

  [[ "$MERGE" == "true" ]] && merger

  tun="$(grep -A5 'tun:' "$CONFIG" | awk '/enable/ {print $2}')"
  if [[ "$tun" == "true" ]]; then
    echo "info: tun enabled."
    tun_setup
    start_service
    forward_device
  else
    start_service
  fi
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
