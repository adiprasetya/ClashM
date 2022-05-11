#!/system/bin/sh

DIR="${0%/*}"
. "$DIR/clashm.config"
CLASHM="$SCRIPTS/clashm.sh"
LOG="${RUN}/run.log"

events=$1
monitor_dir=$2
monitor_file=$3

service_control() {
    if [[ "${monitor_file}" == "disable" ]]; then
        chmod -R 0755 ${SCRIPTS}
        if [[ "${events}" == "d" ]]; then
            ${CLASHM} start &> "$LOG"
        elif [[ "${events}" == "n" ]]; then
            ${CLASHM} stop &> "$LOG"
        fi
    fi
}

service_control