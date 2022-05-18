#!/system/bin/sh

DIR="${0%/*}"
. "$DIR/clashm.config"

# >>> Do not touch! <<< #
# Termux
TERMUX="/data/data/com.termux/files/usr/bin"
if [[ -d "$TERMUX" ]]; then
  PATH="$PATH:$TERMUX"
else
  FISHER="false"
fi

# Suitable iptables
# https://github.com/Magisk-Modules-Repo/v2ray/blob/e1c0885537e4094d785ad219372f04816c5a1d36/v2ray/scripts/v2ray.tproxy#L21
iptables_version="$(iptables -V | grep -o "v1\.[0-9]")"
if [[ "${iptables_version}" = "v1.4" ]]; then
  # fix options for lower version iptables
  export ANDROID_DATA=/data
  export ANDROID_ROOT=/system
  iptables="iptables -w"
elif [[ "${iptables_version}" = "v1.6" ]] || [[ "${iptables_version}" = "v1.8" ]]; then
  iptables="iptables -w 100"
else
  iptables="echo iptables"
fi


# >>> ClashM <<< #

# service script extracted from ( https://t.me/e58695/54 ) 
start_service() {

  if [[ ! -f "${BIN}" ]]; then
    echo "err: clash core is missing."
    print_notification "Core is missing."
    exit 1
  fi

  if [[ ! -f ${CONFIG} ]]; then
    echo "err: configuration file does not exist!"
    print_notification "Configuration file does not exist!"
    exit 1
  fi

  chmod 0755 ${BIN}
  ${BIN} -t -d ${DATA} > ${DATA}/config_error.log
  if [[ "$?" != "0" ]]; then
    echo "err: configuration check failed!"
    print_notification "Configuration check failed!"
    exit 1
  fi

  echo "Date: $(date +%F)" > ${CORE_LOG_FILE}
  echo "Time: $(date +%R)" >> ${CORE_LOG_FILE}
  echo >> ${CORE_LOG_FILE}
  ulimit -SHn 1000000
  nohup ${BUSYBOX} setuidgid 0:3005 ${BIN} -d ${DATA} &>> ${CORE_LOG_FILE} &
  echo -n $! > ${PID_FILE}
  echo "info: clash core started."
  rm -f ${DATA}/config_error.log
}

stop_service() {
  kill -15 `cat ${PID_FILE}` &> /dev/null
  rm -f ${PID_FILE}
  echo "info: clash core stopped."
}

# tproxy script ( https://t.me/e58695/59 )
start_tproxy() {

  # ROUTE RULES
  ip rule add fwmark ${ID} lookup ${ID}
  ip route add local default dev lo table ${ID}
  
  # CLASH_EXTERNAL 链负责处理转发流量
  ${iptables} -t mangle -N CLASH_EXTERNAL
  ${iptables} -t mangle -F CLASH_EXTERNAL

  # 跳过标记为 ${routing-mark} 的 Clash 的本身流量防止回环(安卓环境下不建议)
  # ${iptables} -t mangle -A CLASH_EXTERNAL -j RETURN -m mark --mark ${routing-mark}

  # 目标地址为局域网或保留地址的流量跳过处理
  for subnet in ${intranet[@]}; do
    ${iptables} -t mangle -A CLASH_EXTERNAL -d ${subnet} -j RETURN
  done

  # 其他所有流量转向到 ${tproxy_port} 端口，并打上 mark
  ${iptables} -t mangle -A CLASH_EXTERNAL -p tcp -j TPROXY --on-ip 127.0.0.1 --on-port ${tproxy_port} --tproxy-mark ${ID}
  ${iptables} -t mangle -A CLASH_EXTERNAL -p udp -j TPROXY --on-ip 127.0.0.1 --on-port ${tproxy_port} --tproxy-mark ${ID}

  # 最后让所有流量通过 CLASH_EXTERNAL 链进行处理
  ${iptables} -t mangle -A PREROUTING -j CLASH_EXTERNAL


  # CLASH_LOCAL 链负责处理本机发出的流量
  ${iptables} -t mangle -N CLASH_LOCAL
  ${iptables} -t mangle -F CLASH_LOCAL

  # 跳过 Clash 程序本身发出的流量, 防止回环
  ${iptables} -t mangle -A CLASH_LOCAL -m owner --uid-owner 0 --gid-owner 3005 -j RETURN

  # 跳过标记为 ${routing-mark} 的 Clash 的本身流量防止回环(安卓环境下不建议使用)
  # ${iptables} -t mangle -A CLASH_LOCAL -j RETURN -m mark --mark ${routing-mark}

  # 目标地址为局域网或保留地址的流量跳过处理  
  for subnet in ${intranet[@]}; do
    ${iptables} -t mangle -A CLASH_LOCAL -d ${subnet} -j RETURN
  done

  # 跳过黑名单列表流量
  #  for AID in ${AIDs[@]}; do
  #    ${iptables} -t mangle -A CLASH_LOCAL -m owner --uid-owner ${AID} -j RETURN
  #  done

  # 为本机发出的流量打 mark
  ${iptables} -t mangle -A CLASH_LOCAL -p tcp -j MARK --set-mark ${ID}
  ${iptables} -t mangle -A CLASH_LOCAL -p udp -j MARK --set-mark ${ID}

  # 让本机发出的流量跳转到 CLASH_LOCAL
  # CLASH_LOCAL 链会为本机流量打 mark, 打过 mark 的流量会重新回到 PREROUTING 链上
  ${iptables} -t mangle -A OUTPUT -j CLASH_LOCAL


  # 新建 DIVERT 规则，避免已有连接的包二次通过 TPROXY，理论上有一定的性能提升
  ${iptables} -t mangle -N DIVERT
  ${iptables} -t mangle -F DIVERT

  ${iptables} -t mangle -A DIVERT -j MARK --set-mark ${ID}
  ${iptables} -t mangle -A DIVERT -j ACCEPT

  ${iptables} -t mangle -I PREROUTING -p tcp -m socket -j DIVERT


  # CLASH_DNS_EXTERNAL 链负责处理转发 DNS 流量
  ${iptables} -t nat -N CLASH_DNS_EXTERNAL
  ${iptables} -t nat -F CLASH_DNS_EXTERNAL

  # 转发系统 53 端口至 Clash ${dns_port}
  ${iptables} -t nat -A CLASH_DNS_EXTERNAL -p tcp --dport 53 -j REDIRECT --to-ports ${dns_port}
  ${iptables} -t nat -A CLASH_DNS_EXTERNAL -p udp --dport 53 -j REDIRECT --to-ports ${dns_port}

  ${iptables} -t nat -A PREROUTING -j CLASH_DNS_EXTERNAL


  # CLASH_DNS_LOCAL 链负责处理转发本机 DNS 流量
  ${iptables} -t nat -N CLASH_DNS_LOCAL
  ${iptables} -t nat -F CLASH_DNS_LOCAL

  # 绕过 Clash 本身的 DNS 53 请求流量防止回环
  ${iptables} -t nat -A CLASH_DNS_LOCAL -m owner --uid-owner 0 --gid-owner 3005 -j RETURN

  # 跳过标记为 ${routing-mark} 的 Clash 的本身流量防止回环(安卓环境下不建议)
  # ${iptables} -t nat -A CLASH_DNS_LOCAL -j RETURN -m mark --mark ${routing-mark}

  # 转发系统 53 端口至 Clash ${dns_port}
  ${iptables} -t nat -A CLASH_DNS_LOCAL -p tcp --dport 53 -j REDIRECT --to-ports ${dns_port}
  ${iptables} -t nat -A CLASH_DNS_LOCAL -p udp --dport 53 -j REDIRECT --to-ports ${dns_port}

  ${iptables} -t nat -A OUTPUT -j CLASH_DNS_LOCAL
  
#  ${iptables} -A OUTPUT -d 127.0.0.1 -p tcp -m owner --uid-owner 0 --gid-owner 3005 -m tcp --dport ${tproxy_port} -j REJECT
# 本机直接访问 ${tproxy_port} 会回环. 见 https://github.com/Dreamacro/clash/issues/425

}

stop_tproxy() {
  ip rule del fwmark ${ID} table ${ID}
  ip route del local default dev lo table ${ID}

  ${iptables} -t nat -D PREROUTING -j CLASH_DNS_EXTERNAL
  
  ${iptables} -t nat -D OUTPUT -j CLASH_DNS_LOCAL

  ${iptables} -t nat -F CLASH_DNS_EXTERNAL
  ${iptables} -t nat -X CLASH_DNS_EXTERNAL
  
  ${iptables} -t nat -F CLASH_DNS_LOCAL
  ${iptables} -t nat -X CLASH_DNS_LOCAL

  ${iptables} -t mangle -D PREROUTING -j CLASH_EXTERNAL
  
  ${iptables} -t mangle -D PREROUTING -p tcp -m socket -j DIVERT

  ${iptables} -t mangle -D OUTPUT -j CLASH_LOCAL

  ${iptables} -t mangle -F CLASH_EXTERNAL
  ${iptables} -t mangle -X CLASH_EXTERNAL
  
  ${iptables} -t mangle -F CLASH_LOCAL
  ${iptables} -t mangle -X CLASH_LOCAL
  
  ${iptables} -t mangle -F DIVERT
  ${iptables} -t mangle -X DIVERT

  # ${iptables} -D OUTPUT -d 127.0.0.1 -p tcp -m owner --uid-owner 0 --gid-owner 3005 -m tcp --dport ${tproxy_port} -j REJECT

}


tun_setup() {
  mkdir -p /dev/net
  if [[ ! -L /dev/net/tun ]]; then 
    ln -sf /dev/tun /dev/net/tun
    echo "info: tun setup for first time."
  fi
}

get_tun_mode() {
  tun_mode="$(grep -A5 "tun" $CONFIG | awk '/enable/ {print $2}')"
}

config_merger() {
  echo "info: merge config."
  cp -f "$BASE" "$CONFIG"
  echo >> "$CONFIG"
  cat "$PROXIES" >> "$CONFIG"
}

forward_device() {
  device="$(awk '/device/ {print $2}' "$CONFIG")"
  sleep "$DELAY"
  if ! (ifconfig "$device" &> /dev/null); then
    device="$(ifconfig | grep -Eo '(utun|Meta)')"
  fi
  if [[ -z "$device" ]]; then
    echo "err: tun device interface not found."
    return 1
  fi
  iptables -I FORWARD -o "$device" -j ACCEPT
  iptables -I FORWARD -i "$device" -j ACCEPT
  echo "info: interface $device forwarded."
}

port_opener() {
  TARGET=("$BASE" "$CONFIG")
  $BUSYBOX sed -i "s/.*#.*tproxy/tproxy/" ${TARGET[@]} &> /dev/null
  $BUSYBOX sed -i "s/.*#.*listen/  listen/" ${TARGET[@]} &> /dev/null
}

port_verifier() {
  [[ -z "$1" ]] && return 1
  ss -ap | grep "$BIN_NAME" | grep -om1 "$1"
}

print_notification() {
  if [[ -f "$ICON" ]]; then
    su -lp 2000 -c "cmd notification post -S bigtext -i "file://$ICON" -t 'ClashM' 'CM' '$@'" &> /dev/null
  else
    su -lp 2000 -c "cmd notification post -S bigtext -t 'ClashM' 'CM' '$@" &> /dev/null
  fi
}

start() {
  local pid=`cat ${PID_FILE} 2> /dev/null`
  if (cat /proc/${pid}/cmdline | grep -q ${BIN}); then
    echo "info: clash core has been started."
    print_notification "Core has been started."
    exit 1
  fi

  [[ "$FISHER" == "true" ]] && fishing
  [[ "$MERGE_CONFIG" == "true" ]] && config_merger

  get_tun_mode
  if [[ "$tun_mode" == "true" ]]; then
    echo "info: using tun."
    tun_setup
  else
    port_opener
  fi

  start_service

  if [[ "$tun_mode" == "true" ]]; then
    forward_device
  else
    sleep "$DELAY"

    dns_port="$(port_verifier $(awk -F ':' '/listen/ {print $3}' "$CONFIG"))"
    if [[ -z "$dns_port" ]]; then
      echo "err: dns port not present!"
      print_notification "DNS port not present!"
      stop_service
      exit 1
    fi

    tproxy_port="$(port_verifier $(awk -F ':' '/tproxy-port/ {print $2}' "$CONFIG"))"
    if [[ -z "$tproxy_port" ]]; then
      echo "err: tproxy port not present!"
      print_notification "TPROXY port not present!"
      stop_service
      exit 1
    fi
    echo "info: using tproxy."
    start_tproxy
  fi
  print_notification "Services Started."
}

stop() {
  get_tun_mode
  if [[ "$tun_mode" != "true" ]]; then
    stop_tproxy
    echo "info: tproxy iptables cleared."
  fi
  stop_service
  print_notification "Services Stopped."
}

fishing() {
  print_notification "Fishing..."
  echo "info: fisher begin."
  for i in ${FISH[@]}; do
    echo -n "  - $i "
    ping -w 1 -c 1 $i &> /dev/null && echo "[Success]" || echo "[Failed]"
  done
}


case "$1" in
  start|s)
    start
   ;;
  stop|k)
    stop
   ;;
  *)
    echo "Usage: $0 {start|stop}"
   ;;
esac
