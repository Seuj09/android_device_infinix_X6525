#!/system/bin/sh
if [ -f /metadata/boot_logcat.txt ]; then L=/metadata/boot_logcat.txt; D=/metadata/boot_dmesg.txt
else M=/tmp/m; mkdir -p $M; mount -t f2fs /dev/block/by-name/metadata $M 2>/dev/null; L=$M/boot_logcat.txt; D=$M/boot_dmesg.txt; fi

echo "## WHY SYSTEM_SERVER DIED (lines before first DeadSystemException)"
LN=$(grep -n "DeadSystemException" $L | head -n 1 | cut -d: -f1)
if [ -n "$LN" ]; then
  S=$((LN - 45)); [ $S -lt 1 ] && S=1
  sed -n "${S},${LN}p" $L | grep -vE "avc:|KernelMemoryBandwidth"
fi
echo "## TOMBSTONES / ANR"
ls -lt /data/tombstones /data/anr 2>&1 | head -n 12
echo "## WIFI / DHCP / SUPPLICANT (last 35)"
grep -iE "DhcpClient|IpClient|WifiClientModeImpl|wpa_supplicant|WifiVendorHal|SupplicantSta|IWifi" $L | tail -n 35
echo "## SUSPEND / WDT / POWER IN DMESG"
grep -iE "suspend|PM:|wdt|watchdog|panic|reboot|sprd_pdbg|sleep" $D | tail -n 25
[ -n "$M" ] && umount $M 2>/dev/null
