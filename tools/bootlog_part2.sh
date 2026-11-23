#!/system/bin/sh
# Pulls Settings/SystemUI/Launcher crashes, ANRs, and 5GHz Wi-Fi errors from /metadata/boot_logcat.txt
M=/tmp/m; mkdir -p $M
mount -t f2fs /dev/block/by-name/metadata $M 2>/dev/null
L=$M/boot_logcat.txt
strip() { sed -E 's/^[0-9-]+ [0-9:.]+ +[0-9]+ +[0-9]+ //'; }

echo "## TICK"; cat $M/boot_tick.txt 2>/dev/null
echo "## FATAL EXCEPTIONS / CRASHES (Settings / SystemUI / Launcher / SystemServer)"
grep -E "FATAL EXCEPTION|AndroidRuntime:|Process: com\.android\.(settings|systemui|launcher)|Caused by:|F DEBUG +: (Cmdline:|Abort message|signal )" $L | strip | tail -n 55
echo "## WIFI / 5GHZ ERRORS"
grep -iE "WifiNl80211|WifiHal|wpa_supplicant|supplicant|5g|band|country|regdom|sprdwl|unisoc.*wifi" $L | grep -E " (W|E|F) " | strip | sort -u | tail -n 30
umount $M 2>/dev/null
