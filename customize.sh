# installer checker
if [[ $BOOTMODE != true ]]; then
  abort "Error: Install in Magisk Manager."
fi

# device support checker
if [[ "$ARCH" != "arm64" ]]; then
  abort "Error: Unsupported device."
fi

DATA="/data/adb/$MODID"
SERVICE="/data/adb/service.d/${MODID}.sh"

ui_print "- Data directory: $DATA"

# setup environment
if [[ -f "${DATA}/proxies.yaml" ]]; then
  cp -f "${DATA}/proxies.yaml" "${MODPATH}/data"
else 
  cp -f "${MODPATH}/data/.example.yaml" "${MODPATH}/data/proxies.yaml"
fi

if [[ -d "${DATA}" ]]; then
  ui_print "- Old data directory exists,"
  ui_print "  Moved to ${DATA}.bak"
  if [[ -d "${DATA}.bak" ]]; then
    ui_print "- Old $MODID.bak will replaced."
    rm -rf "${DATA}.bak"
  fi
  mv -f "${DATA}" "${DATA}.bak"
fi

mv -f "${MODPATH}/data" "${DATA}"

mkdir -p "$MODPATH/run"

# replacing variable
sed -i "s|MODID|$MODID|" \
"$MODPATH/scripts/configuration" \
"$MODPATH/uninstall.sh" \
"$MODPATH/service.sh"

# install service.d
mv -f "$MODPATH/service.sh" "$SERVICE"

# set environment permission
set_perm_recursive "${MODPATH}" 0 0 0755 0644
set_perm_recursive "${DATA}" 0 0 0644 0644
set_perm_recursive "${MODPATH}/scripts" 0 3005 0755 0755
set_perm_recursive "${MODPATH}/bin" 0 3005 0755 0755
set_perm_recursive "${SERVICE}" 0 0 0755 0755