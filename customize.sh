
if [[ "$BOOTMODE" != true ]]; then
  abort "Install in Magisk Manager!"
fi

if [[ "$ARCH" != "arm"* ]]; then
  abort "Only for arm devices!"
fi

BIN="$MODPATH/bin"
if [[ "$IS64BIT" != "true" ]]; then
  ui_print "- Your devices isn't 64bit. PROCESS-NAME rules won't work"
fi

# gunzip "$BIN/$ARCH.gz"
mv -f "$BIN/$ARCH" "$BIN/meta"
rm -f "$BIN/"*.gz

DATA="/data/adb/$MODID"
SERVICE="/data/adb/service.d/$MODID.sh"

ui_print "- Setup environment"
if [[ -f "$DATA/config.yaml" ]]; then
  cp -f "$DATA/config.yaml" "$MODPATH/data"
else 
  cp -f "$MODPATH/data/.example.yaml" "$MODPATH/data/config.yaml"
fi


DATE="$(date "+%F")"
if [[ -d "$DATA" ]]; then
  ui_print "- Old data directory exists,"
  ui_print "  Moved to $DATA.$DATE"
  if [[ -d "$DATA.$DATE" ]]; then
    ui_print "- Old $MODID.$DATE will replaced"
    rm -rf "$DATA.$DATE"
  fi
  mv -f "$DATA" "$DATA.$DATE"
fi

mv -f "$MODPATH/data" "$DATA"
mkdir -p "$MODPATH/run"
ui_print "- Data directory: $DATA"

ui_print "- Replacing variable"
sed -i "s|MODID|$MODID|" \
"$MODPATH/scripts/configuration" \
"$MODPATH/uninstall.sh" \
"$MODPATH/service.sh"

ui_print "- Installing service script"
mv -f "$MODPATH/service.sh" "$SERVICE"

ui_print "- Set environment permission"
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm_recursive "$DATA" 0 0 0644 0644
set_perm_recursive "$MODPATH/scripts" 0 3005 0755 0755
set_perm_recursive "$MODPATH/bin" 0 3005 0755 0755
set_perm_recursive "$SERVICE" 0 0 0755 0755
