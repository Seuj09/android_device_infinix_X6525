#!/system/bin/sh
echo "=== 1. RAM & ZRAM ==="
free -m
cat /proc/swaps
for f in /sys/block/zram0/disksize /sys/block/zram0/comp_algorithm /sys/block/zram0/mm_stat /sys/block/zram0/backing_dev /proc/sys/vm/kcompressd /proc/sys/vm/swappiness /proc/sys/vm/page-cluster /proc/sys/vm/workingset_protection /sys/kernel/mm/lru_gen/enabled; do
  [ -r "$f" ] && echo "$f: $(cat "$f" 2>/dev/null)"
done

echo "=== 2. PROPS & REBOOT REASON ==="
for p in ro.bootmode persist.sys.boot.reason.history ro.boot.ddrsize ro.boot.ddrsize.range ro.vendor.ramconfig dalvik.vm.heapgrowthlimit dalvik.vm.heapsize ro.config.low_ram; do
  echo "[$p]: $(getprop "$p")"
done
getprop | grep -E "ro\.lmk\.|ro\.vendor\.lmk\.|zram"

echo "=== 3. RECENT LMKD / OOM / AM_KILL (logcat) ==="
logcat -d -b main,events 2>/dev/null | grep -iE "lowmemorykiller|lmkd|OutOfMemoryError|am_kill|am_low_memory|am_proc_died.*chrome" | tail -n 30

echo "=== 4. KERNEL OOM / ZRAM / KCOMPRESS / BUG / WDT (current dmesg) ==="
dmesg | grep -iE "oom|out of memory|kill process|zram|kcompress|swap|BUG:|WARNING:|Call trace|blocked for more than|soft lockup|watchdog|panic" | tail -n 35

echo "=== 5. PREVIOUS BOOT CRASH TAIL (/metadata/boot_dmesg.txt & boot_logcat.txt) ==="
if [ -r /metadata/boot_dmesg.txt ]; then
  echo "--- /metadata/boot_dmesg.txt matches ---"
  grep -iE "oom|out of memory|kill process|zram|kcompress|swap|BUG:|WARNING:|Call trace|blocked for more than|soft lockup|watchdog|panic" /metadata/boot_dmesg.txt | tail -n 25
  echo "--- /metadata/boot_dmesg.txt last 15 lines ---"
  tail -n 15 /metadata/boot_dmesg.txt
fi
if [ -r /metadata/boot_logcat.txt ]; then
  echo "--- /metadata/boot_logcat.txt OOM/kill/fatal ---"
  grep -iE "lowmemorykiller|lmkd|OutOfMemory|FATAL EXCEPTION|Watchdog|DeadSystem" /metadata/boot_logcat.txt | tail -n 20
fi
