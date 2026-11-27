#!/bin/sh
adb shell <<'DIAG_EOF'
echo "=== 1. PSTORE LIST & RAMOOPS ==="
ls -la /sys/fs/pstore
for f in /sys/fs/pstore/unused-ramoops* /sys/fs/pstore/console-ramoops* /sys/fs/pstore/dmesg-ramoops*; do
    [ -e "$f" ] || continue
    echo "--- $f (bytes=$(wc -c < "$f")) key ---"
    strings "$f" | grep -iE "X6525_|init:|fs_mgr|mount_all|metadata|userdata|cache|selinux|wdt|watchdog|musb|adbd|apex|panic|reboot|restart|oops|fatal" | head -n 80
    echo "--- $f tail ---"
    strings "$f" | tail -n 100
done
[ -e /sys/fs/pstore/pmsg-ramoops-0 ] && {
    echo "--- pmsg-ramoops-0 (non-adb tail) ---"
    strings /sys/fs/pstore/pmsg-ramoops-0 | grep -vE "adbd|ServiceManager|SELinux: Loaded" | tail -n 30
}

echo "=== 2. CACHE BOOTTRACE & LOGS ==="
mount -t f2fs /dev/block/by-name/cache /cache 2>&1
echo "mount_cache_rc=$?"
ls -la /cache 2>&1
if [ -s /cache/boottrace.txt ]; then
    echo "--- /cache/boottrace.txt ---"
    cat /cache/boottrace.txt
fi
if [ -s /cache/boot_dmesg.txt ]; then
    echo "--- /cache/boot_dmesg.txt key events ---"
    grep -iE "X6525_|init:|fs_mgr|mount_all|metadata|userdata|selinux|wdt|watchdog|musb|usb|adbd|apex|panic|error|fail" /cache/boot_dmesg.txt | tail -n 100
    echo "--- /cache/boot_dmesg.txt tail ---"
    tail -n 60 /cache/boot_dmesg.txt
fi
if [ -s /cache/boot_logcat.txt ]; then
    echo "--- /cache/boot_logcat.txt tail ---"
    tail -n 60 /cache/boot_logcat.txt
fi
umount /cache 2>/dev/null

echo "=== 3. METADATA/CACHE/USERDATA/MISC HEAD ==="
echo "--- misc ---"
dd if=/dev/block/by-name/misc bs=1 count=64 2>/dev/null | xxd
for p in metadata cache userdata; do
    echo "--- $p (1024..1056) ---"
    dd if="/dev/block/by-name/$p" bs=1 skip=1024 count=32 2>/dev/null | xxd
done
DIAG_EOF