#!/data/data/com.termux/files/usr/bin/bash

# FISHER WILL NOT WORK IF TERMUX DOES NOT INSTALLED!
FISH=(
 "example.com"
)


which curl &> /dev/null || { echo "Install curl!"; exit 1; }

fishing() {
  echo "info: fisher begin."
  for i in ${FISH[@]}; do
    echo -n "  - $i "
    curl -LI $i &> /dev/null && echo "[Success]" || echo "[Failed]"
  done
}

fishing
