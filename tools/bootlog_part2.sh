#!/system/bin/sh
echo "## BOOT REASON & CMDLINE"
getprop | grep -iE "bootreason|bootmode|reboot|reset"
cat /proc/cmdline
echo "## WDT SYSFS / PARAMS"
ls -la /sys/module/sprd_wdt_fiq/parameters /sys/module/sprd_pmic_wdt/parameters /dev/watchdog* 2>&1
for f in /sys/module/sprd_wdt_fiq/parameters/* /sys/module/sprd_pmic_wdt/parameters/*; do [ -r "$f" ] && echo "$f = $(cat $f)"; done
echo "## DMESG WDT / SUSPEND / SYSDUMP / RESET"
dmesg 2>/dev/null | grep -iE "bootreason|wdt|watchdog|sysdump|suspend|PM:|reset reason|panic|oops" | head -n 45
