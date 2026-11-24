#!/system/bin/sh
echo "## LATEST ANR (system_server watchdog cause)"
F=$(ls -t /data/anr/anr_* 2>/dev/null | head -n 1)
[ -n "$F" ] && echo "--- $F ---" && head -n 45 "$F"
echo "## LIVE LOGCAT: BLUETOOTH CRASH"
logcat -b all -d 2>/dev/null | grep -iE "bluetooth|bt_hci|bt_vendor|gd_stack|Abort message" | tail -n 25
echo "## LIVE LOGCAT: WIFI / DHCP / IPCLIENT"
logcat -b all -d 2>/dev/null | grep -iE "DhcpClient|IpClient|WifiClientMode|wpa_supplicant|SupplicantSta|WifiVendorHal" | tail -n 30
echo "## LIVE DMESG: SUSPEND / POWER / WDT"
dmesg 2>/dev/null | grep -iE "suspend|PM:|wdt|sprd_drm|backlight|reboot" | tail -n 25
