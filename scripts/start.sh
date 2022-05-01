#!/system/bin/sh

DIR="/data/adb/modules/REPLACE"
SCRIPTS="${DIR}/scripts"
RUN="${DIR}/run"
PID_FILE="${RUN}/clash.pid"
RUN_FILE="${RUN}/run.log"

wait_until_login() {
  # in case of /data encryption is disabled
  while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
  done

  # we doesn't have the permission to rw "/sdcard" before the user unlocks the screen
  local TEST_FILE="/sdcard/Android/.ClashM"
  true > "$TEST_FILE"
  while [ ! -f "$TEST_FILE" ]; do
    true > "$TEST_FILE"
    sleep 1
  done
  rm -f "$TEST_FILE"
}

wait_until_login

[[ -f ${PID_FILE} ]] && rm -f ${PID_FILE}

chmod -R 0755 ${SCRIPTS}

if [[ ! -f ${DIR}/manual ]]; then
  true > ${RUN_FILE}
  chmod 644 ${RUN_FILE}
  ${SCRIPTS}/clashm.sh start &> "$RUN_FILE"
fi
