#!/system/bin/sh
M=/tmp/m; mkdir -p $M
mount -t f2fs /dev/block/by-name/metadata $M 2>/dev/null
L=$M/boot_logcat.txt; P=$M/boot_ps.txt; R=$M/boot_props.txt
strip() { sed -E 's/^[0-9-]+ [0-9:.]+ +[0-9]+ +[0-9]+ //'; }

echo "## RESTARTING SVCS"
grep -E "^\[init\.svc\..*\]: \[restarting\]" $R 2>/dev/null
echo "## SYSTEMUI / LAUNCHER / SETTINGS IN PS"
grep -E "systemui|launcher|settings|trebuchet|quickstep|system_server|wificond|wpa_supplicant|wifi" $P 2>/dev/null
echo "## TOP ERRORS IN LOGCAT (last 2000 lines, deduped)"
tail -n 2000 $L | grep -E " (E|F) " | grep -vE "keystore2|KernelMemoryBandwidth" | strip | sort | uniq -c | sort -nr | head -n 25
echo "## WIFICOND / WIFI LOGCAT"
grep -iE "wificond|wifi_hal|WifiNative|WifiVendorHal|sprdwl|wlan0" $L | strip | tail -n 25
umount $M 2>/dev/null
