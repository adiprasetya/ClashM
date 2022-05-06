#!/system/bin/sh

# >>> ClashM Configuration <<< #

# Customizable
MERGE_CONFIG="true" # AUTO MERGE BETWEEN BASE AND PROXIES
FISHER="false" # FISHER WILL NOT WORK IF TERMUX DOES NOT INSTALLED!
BIN_NAME="clash"
ID="2022"

# Advanced
# DIR="${0%/*}"
DIR="/data/adb/modules/REPLACE"
DATA="${DIR}/data"
CONFIG="${DATA}/config.yaml"
BASE="${DATA}/base.yaml"
PROXIES="${DATA}/proxies.yaml"
RUN="${DIR}/run"
PID_FILE="${RUN}/clash.pid"
RUN_FILE="${RUN}/run.log"
CORE_LOG_FILE="${RUN}/core.log"
SCRIPTS="$DIR/scripts"
BIN="$DIR/bin/$BIN_NAME"
BUSYBOX="/data/adb/magisk/busybox"


# >>> Do not touch! <<< #
# Termux
TERMUX="/data/data/com.termux/files/usr/bin"
if [[ -d "$TERMUX" ]]; then
  PATH="$PATH:$TERMUX"
else
  FISHER="false"
fi

# Bypass Private IP
intranet=(0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.0.0.0/24 192.0.2.0/24 192.88.99.0/24 192.168.0.0/16 198.51.100.0/24 203.0.113.0/24 224.0.0.0/4 233.252.0.0/24 240.0.0.0/4 255.255.255.255/32)

# Special AIDs (include/private/android_filesystem_config.h):
AIDs=(1001 1002 1003 1004 1005 1006 1007 1008 1009 1010 1011 1012 1013 1014 1015 1016 1017 1018 1019 1020 1021 1022 1023 1024 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034 1035 1036 1037 1038 1039 1040 1041 1042 1043 1044 1045 1046 1047 1048 1049 1050 2001 2002 3001 3002 3003 3004 3005 3006 3007 3008 3009 3010 9997 9998 9999)

# Suitable iptables (https://github.com/Magisk-Modules-Repo/v2ray)
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
    exit 1
  fi

  if [[ ! -f ${CONFIG} ]]; then
    echo "err: configuration file does not exist!！"
    exit 1
  fi

  chmod 0755 ${BIN}
  ${BIN} -t -d ${DATA} > ${RUN}/config_error.log
  if [[ "$?" != "0" ]]; then
    echo "err: configuration check failed！"
    exit 1
  fi

  echo ">>> Core Log <<<" > ${CORE_LOG_FILE}
  echo "Date: $(date +%F)" >> ${CORE_LOG_FILE}
  echo "Time: $(date +%R)" >> ${CORE_LOG_FILE}
  echo >> ${CORE_LOG_FILE}
  ulimit -SHn 1000000
  nohup ${BUSYBOX} setuidgid 0:3005 ${BIN} -d ${DATA} &>> ${CORE_LOG_FILE} &
  echo -n $! > ${PID_FILE}
  echo "info: clash core started."
  rm -f ${RUN}/config_error.log
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


# functioning stuff
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
  echo "info: merging config"
  cp -f "$BASE" "$CONFIG" && echo "  - add base."
  echo >> "$CONFIG"
  cat "$PROXIES" >> "$CONFIG" && echo "  - merge proxies."
}

forward_device() {
  device="$(cat $CONFIG | grep device | awk '{print $2}')"
  if [[ -z "$device" ]]; then
    device="$(ip link show | grep -Eo '(utun|Meta)')"
  fi
  iptables -I FORWARD -o "$device" -j ACCEPT
  iptables -I FORWARD -i "$device" -j ACCEPT
  [[ "$?" == "0" ]] && echo "info: interface $device forwarded."
}

custom_script() {
  [[ "$FISHER" == "true" ]] && $SCRIPTS/fisher.sh
}

start() {
  local pid=`cat ${PID_FILE} 2> /dev/null`
  if (cat /proc/${pid}/cmdline | grep -q ${BIN}); then
    echo "info: clash core has been started."
    exit 1
  fi

  custom_script
  [[ "$MERGE_CONFIG" == "true" ]] && config_merger

  get_tun_mode
  [[ "$tun_mode" == "true" ]] && { echo "info: using tun"; tun_setup; }

  start_service

  if [[ "$tun_mode" == "true" ]]; then
    forward_device
  else
    tproxy_port="$(grep "tproxy-port" $CONFIG | awk -F ':' '{print $2}')"
    dns_port="$(grep "listen" $CONFIG | awk -F ':' '{print $3}')"
    if [[ -z "$dns_port" ]]; then
      echo "err: dns port not present!"
      stop_service
      exit 1
    fi
    if [[ -z "$tproxy_port" ]]; then
      echo "err: tproxy port not present!"
      stop_service
      exit 1
    fi
    echo "info: using tproxy"
    start_tproxy
  fi
}

stop() {
  get_tun_mode
  if [[ "$tun_mode" != "true" ]]; then
    stop_tproxy
    echo "info: tproxy stopped"
  fi
  stop_service
}

case "$1" in
  start|s)
    start
   ;;
  stop|k)
    stop
   ;;
  *)
    echo "Usage: ClashM {start|stop}"
   ;;
esac
