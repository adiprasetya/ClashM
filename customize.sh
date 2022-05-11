# installer checker
if [[ $BOOTMODE != true ]]; then
  abort "Error: Install in Magisk Manager."
fi

# device support checker
if [[ "$ARCH" != "arm64" ]]; then
  abort "Error: Unsupported device."
fi

# tproxy support checker
TPROXY="$(zcat /proc/config.gz | awk -F '=' '/TPROXY/ {print $2}')"
if [[ "$TPROXY" != "y" ]]; then
  abort "Error: Unsupported TPROXY."
fi

DATA="/data/adb/$MODID"
BIN="${MODPATH}/bin"
RUN="${MODPATH}/run"
SCRIPTS="${MODPATH}/scripts"

ui_print "- data directory: $DATA"

# setup environment
if [[ -d "${DATA}" ]]; then
  ui_print "- old data directory exists,"
  ui_print "  moved to ${DATA}.bak"
  [[ -d "${DATA}.bak" ]] && ui_print "- old $MODID.bak will replaced."
  mv -f "${DATA}" "${DATA}.bak"
fi
mv -f "${MODPATH}/data" "${DATA}"
mkdir -p "$BIN"
mkdir -p "$SCRIPTS"
mkdir -p "$RUN"
[[ ! -f "${DATA}/proxies.yaml" ]] && \
cp -f "${DATA}/.example.yaml" "${DATA}/proxies.yaml"

# replacing MOD ID
sed -i "s|REPLACE|$MODID|" "$MODPATH/scripts/clashm.config"

# set environment permission
set_perm_recursive "${MODPATH}" 0 0 0755 0644
set_perm_recursive "${DATA}" 0 3005 0644 0644
set_perm_recursive "${MODPATH}/scripts" 0 3005 0755 0755
set_perm_recursive "${MODPATH}/bin" 0 3005 0755 0755