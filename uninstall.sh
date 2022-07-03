remove_data_dir() {
  rm -rf /data/adb/MODID*
}

remove_service() {
  rm -f /data/adb/service.d/MODID.sh
}

remove_data_dir
remove_service
