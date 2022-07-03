#!/system/bin/sh

DIR="${0%/*}"
. "$DIR/configuration"
MAIN="$SCRIPTS/main.sh"

events=$1
monitor_dir=$2
monitor_file=$3

service_control() {
    if [[ "$monitor_file" == "disable" ]]; then
        if [[ "$events" == "d" ]]; then
            "$MAIN" start &> "$RUN_FILE"
        elif [[ "$events" == "n" ]]; then
            "$MAIN" stop &> "$RUN_FILE"
        fi
    fi
}

service_control