#!/system/bin/sh
echo "## KERNEL WARNING AT ~37s"
dmesg 2>/dev/null | grep -B3 -A18 -E "WARNING:|BUG:|Oops" | head -n 30
echo "## POWER / SUSPEND SYSFS"
for f in /sys/power/state /sys/power/mem_sleep /sys/power/autosleep /sys/power/pm_async /sys/power/wakeup_count; do
  [ -r "$f" ] && echo "$f: $(cat $f 2>&1)"
done
echo "## SUSPEND STATS"
cat /sys/kernel/debug/suspend_stats 2>/dev/null || grep "" /sys/power/suspend_stats/* 2>/dev/null
echo "## SYSTEM_SUSPEND & POWER HAL IN PS / LOGCAT"
ps -A -o PID,USER,STAT,NAME | grep -iE "suspend|power|wdt|thermal"
logcat -b all -d 2>/dev/null | grep -iE "SystemSuspend|PowerManagerService|autosleep|suspend_blocker|vendor\.unisoc\.hardware\.power" | tail -n 25
