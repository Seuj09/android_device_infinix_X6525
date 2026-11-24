#!/system/bin/sh
# Works in booted Android (adb shell sh) OR in recovery!
M=/tmp/m
if [ -f /metadata/boot_logcat.txt ]; then
  L=/metadata/boot_logcat.txt; D=/metadata/boot_dmesg.txt; R=/metadata/boot_props.txt
else
  mkdir -p $M; mount -t f2fs /dev/block/by-name/metadata $M 2>/dev/null
  L=$M/boot_logcat.txt; D=$M/boot_dmesg.txt; R=$M/boot_props.txt
fi
strip() { sed -E 's/^[0-9-]+ [0-9:.]+ +[0-9]+ +[0-9]+ //'; }

echo "## PSTORE (screen-off panic/reboot cause)"
ls -la /sys/fs/pstore 2>&1
for f in /sys/fs/pstore/*; do [ -f "$f" ] && echo "--- $f ---" && tail -n 60 "$f"; done
echo "## BOOTTIME PROPS"
grep -E "^\[ro\.boottime\." $R 2>/dev/null | head -n 30
echo "## SOFT-REBOOT / SYSTEM_SERVER / SF / WATCHDOG CRASHES"
grep -E "FATAL EXCEPTION|AndroidRuntime:|Watchdog:|F DEBUG +: (Cmdline:|signal |Abort message|#00 )|Service '(surfaceflinger|zygote)' .* (exited|received)" $L $D 2>/dev/null | strip | tail -n 45
echo "## WIFI / DHCP / IP CONFIG FAILURE"
grep -iE "DhcpClient|IpClient|WifiClientModeImpl|wpa_supplicant|WifiVendorHal|sprdwl|wlan0.*(fail|err|disconnect|timeout|ip)" $L 2>/dev/null | grep -E " (W|E|F) " | strip | sort -u | tail -n 35
[ -d $M ] && umount $M 2>/dev/null
