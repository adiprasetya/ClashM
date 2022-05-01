#!/data/data/com.termux/files/usr/bin/bash

# FISHER WILL NOT WORK IF TERMUX DOES NOT INSTALLED!
FISH=(
 "example.com"
)

main() {
  echo "info: fisher begin"
  which curl &> /dev/null || { echo "err: install curl!"; exit 1; }
  for i in ${FISH[@]}; do
    echo -n "  - $i "
    curl -I $i &> /dev/null && echo "[Success]" || echo "[Failed]"
  done
  echo "info: fisher finished"
}

main