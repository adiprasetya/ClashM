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

# setup environment
mkdir -p "${MODPATH}/bin"
mkdir -p "${MODPATH}/data"
mkdir -p "${MODPATH}/run"
mkdir -p "${MODPATH}/scripts"
cp -f "${MODPATH}/data/.example.yaml" "${MODPATH}/data/proxies.yaml"

# replacing MOD ID
sed -i "s|REPLACE|$MODID|" "$MODPATH/scripts/clashm.sh"
sed -i "s|REPLACE|$MODID|" "$MODPATH/scripts/inotify.sh"
sed -i "s|REPLACE|$MODID|" "$MODPATH/scripts/start.sh"

# set environment permission
set_perm_recursive "${MODPATH}" 0 0 0755 0644
set_perm_recursive "${MODPATH}/data" 0 3005 0755 0644
set_perm_recursive "${MODPATH}/scripts" 0 3005 0755 0755
set_perm_recursive "${MODPATH}/bin" 0 3005 0755 0755