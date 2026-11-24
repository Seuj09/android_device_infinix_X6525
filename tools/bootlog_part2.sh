#!/system/bin/sh
echo "## KERNEL WARNING / OOPS / CALL TRACE IN DMESG"
dmesg 2>/dev/null | grep -n -B2 -A22 -E "WARNING:|BUG:|Oops|Internal error|Unable to handle|Call trace:" | head -n 75
echo "## WLAN0 / WIFI / DHCP IN LOGCAT"
logcat -b all -d 2>/dev/null | grep -iE "wlan0|IpClient\.wlan0|DhcpClient|WifiClientModeImpl|WifiVendorHal|SupplicantSta" | grep -v "usb0" | tail -n 35
