remove_data_dir() {
  rm -rf /data/adb/REPLACE
}

remove_service() {
  rm -f /data/adb/service.d/REPLACE.sh
}

remove_data_dir
remove_service
